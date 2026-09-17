# Keeping a Campaign Destination Until the Right Person Claims It — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A mail is sent to `midax74173@kolsea.com`. Someone clicks its CTA and signs in as `huan@drumee.org` — nothing happens, correctly. They sign out and sign in as `midax74173@kolsea.com` — and the checkout **opens with the coupon applied**, because that is the person the link was written for and the click did happen.

Today the second half fails: the destination is destroyed by the first, refused login.

**Architecture:** One rule, applied in four places — **only consume the intent when you are going to act on it.** A refusal must leave it exactly as it found it. Nothing new is stored and no new carrier is invented; what changes is the order of "read" and "decide", and who is allowed to clear.

**Tech stack:** ui-team `libs/billing-deep-link` + desk router/module, signin's post-login hand-off.

---

## The shape of the bug

`_maybeOpenBillingDeepLink` reads before it decides:

```js
const preselect = billingDeepLink.consume();                      // destroys it
if (!preselect) return false;
if (!billingDeepLink.isForCurrentUser(preselect)) return false;   // refused — already gone
if (!canUpgradePlan()) return false;                              // refused — already gone
```

`consume()` removes the key and returns the value. Both gates below it therefore
throw away a destination that nobody has acted on. A wrong-account sign-in is
indistinguishable, afterwards, from a destination that was used.

The same happens twice more on the way in — see Findings 2 and 3 — so by the
time the right person signs in, every copy is gone.

---

## Finding 1 — "refused" and "used" are being treated as the same outcome

They are opposites, and the difference is the whole feature:

| outcome | what should happen to the intent |
|---|---|
| the right account signs in, billing opens | **consumed** — it must not replay after a later sign-out (the bug fixed in `e4230226`) |
| a different account signs in | **kept** — the person it was written for has not had their chance yet |
| the account cannot buy (`canUpgradePlan` false) | **kept** — nothing was offered to them, and eligibility can change |

Today all three consume. The fix is to move the read after the decision, which
needs a `peek()` beside the existing `consume()`.

**THIS MUST NOT REGRESS SINGLE-USE.** `e4230226` exists because the destination
used to replay for the same account after a sign-out. That remains correct and
is not being relaxed: a MATCHING account still consumes, and consuming is still
the thing that makes it single-use. What changes is that a REFUSAL stops
counting as a use.

---

## Finding 2 — the signin hand-off gives it away before anyone has checked

`billingReturnUrl()` runs on `case "ok"` — a completed sign-in — reads the
stored intent, clears it, and writes the destination into the URL so it can ride
the host switch. It does that for **whoever** just signed in.

So on a wrong-account sign-in the destination is taken off the origin that holds
it and handed to a session that is about to be refused. That is the copy the
right person would have found on their next attempt: `Butler.logout` returns the
visitor to the main domain, which is exactly where this cleared it from.

**signin is the best place to decide**, and the only one where all three facts
are present at once: the identity of who just signed in (`data.user.profile`,
already read a few lines below for the onboarding branch), the intent, and the
origin still holding it. A mismatch there should be a no-op — no URL args, no
clear — leaving the intent for a later sign-in.

---

## Finding 3 — the host-switch disarm is unconditional

`e4230226` added, correctly, in the router:

```js
if (this.changeHost(Organization.host())) {
  billingDeepLink.disarm();   // the URL is the carrier from here
  return;
}
```

That is right when the URL genuinely carries the destination onward — which is
true only when signin put it there. With Finding 2 fixed, a mismatched sign-in
leaves the URL clean, and disarming would then throw away the copy nobody has
claimed.

It has to become conditional on the same question: **is this session the one the
link was written for?** If yes, the URL is carrying it and this copy is
redundant. If no, this copy is the last one and must stay.

---

## Finding 4 — sessionStorage is the right lifetime, and it bounds this

The intent lives in `sessionStorage`, deliberately: `billing-deep-link`'s own
docblock says an "open billing" intent should die with the tab rather than
surprise someone days later. Retention therefore means **within this tab**, and
the scenario in the Goal is exactly that — sign out, sign in again, same tab.

Close the tab and the destination is gone; the recipient clicks the CTA again.
That is the correct trade and should not be "fixed" by moving to localStorage,
which would make a forwarded link resurface on an unrelated day.

**One consequence worth stating:** a wrong account signing in repeatedly leaves
the intent armed for the life of the tab. That is the intended behaviour — it is
waiting for its recipient — and it is bounded by the tab, by the recipient
marker, and by the coupon's own server-side rules.

---

## Global constraints

- **Only consume when you act.** Every refusal path must leave the intent
  byte-for-byte as it found it. This is the whole plan; if a task cannot satisfy
  it, the task is wrong.
- **Single-use on the happy path is not being relaxed.** A matching account
  consumes, and `e4230226`'s regression must stay fixed. Both properties get a
  test, and they are easy to break in each other's name.
- **No new storage, no new carrier, no lifetime change.** sessionStorage and the
  existing URL forms are enough; Finding 4 says why localStorage would be wrong.
- **The recipient check stays advisory.** `mkt_coupon_reserve` has no recipient
  allowlist, so this decides who gets walked into checkout automatically, not
  who may redeem. Nothing here should read as enforcement.
- **A link with no marker keeps working.** Absent means "not bound", not
  "refuse" — every link written before the marker existed, and every hand-built
  one, must still open for whoever signs in.

---

## File structure

```
ui-team/
  src/drumee/libs/billing-deep-link.js   MODIFIED  peek()
  src/drumee/modules/desk/index.js       MODIFIED  decide, then consume
  src/drumee/router/index.js             MODIFIED  disarm only for the recipient
  tests/billing-deep-link-promo.test.js  MODIFIED  retention + single-use together

signin/
  src/widgets/form/index.js              MODIFIED  hand off only to the recipient
  tests/billing-return-url.test.js       MODIFIED
```

---

# REPO 1 — ui-team

### Task 1: read without taking

- [ ] Add `peek()` to `libs/billing-deep-link.js`: the body of `consume()`
      without the `removeItem`, returning the same shape (stored value first,
      then the URL fallback, else null).
- [ ] Implement `consume()` in terms of `peek()` so the two cannot answer
      differently — the URL fallback in particular has to behave identically or
      a direct click and a stored intent would take different paths.
- [ ] Docblock the trio as one decision: `peek` reads, `consume` reads and takes,
      `disarm` takes without reading. State that a refusal must use `peek`.
- [ ] Export it.

### Task 2: decide before consuming

- [ ] In `_maybeOpenBillingDeepLink`, replace the opening `consume()` with
      `peek()`, run BOTH gates against it, and only then `consume()` — discarding
      its return, since `peek` already produced the value.
- [ ] The two refusals must return false having taken nothing. Comment each with
      what keeps the intent alive and why: a wrong account has not used the
      recipient's chance, and `canUpgradePlan` can flip (ownership, a payment
      backend that had not loaded).
- [ ] Do NOT reorder the gates relative to each other; only their position
      relative to the read changes.

### Task 3: disarm only for the recipient

- [ ] Make the router's `billingDeepLink.disarm()` conditional on the intent
      being for the signed-in account — `peek()` the value and pass it to
      `isForCurrentUser`.
- [ ] Explain the asymmetry in place: for the recipient, signin has put the
      destination on the URL and this copy is redundant; for anyone else the URL
      is clean (Task 5) and this copy is the last one.
- [ ] An intent with no marker still disarms — it is bound to nobody, signin
      handed it to the URL, and keeping it would restore the replay bug.

### Task 4: tests

- [ ] **The scenario from the Goal, as one case:** addressed to A; B signs in →
      refused AND still armed; A signs in → opens AND now cleared.
- [ ] `canUpgradePlan` refusing leaves the intent armed.
- [ ] **Single-use is unchanged:** A signs in, opens, and a second pass with the
      same account gets nothing. This is the `e4230226` regression and it must be
      asserted in the same file as the retention cases, so a future change cannot
      satisfy one by breaking the other.
- [ ] `peek()` does not mutate; `consume()` does; both answer identically on the
      same input, including via the URL fallback.
- [ ] The router disarms for the recipient and does not for anyone else.

---

# REPO 2 — signin

### Task 5: hand off only to the person it is for

- [ ] In `checkLoginStatus`'s `case "ok"`, resolve the signed-in address —
      `data.user.profile.email` is already read a few lines down for the
      onboarding branch, so no new source is needed. Fall back to whatever the
      form holds if that is absent.
- [ ] Before building the return URL, compare the stored intent's `for` against
      that address using the SAME FNV-1a as everywhere else. Reuse the existing
      helper rather than adding a third copy of the hash — there are already two
      (analytics-server and ui-team) and a suite pins them equal.
- [ ] On a mismatch: return null. No URL args, no clear, plain reload. The intent
      stays on this origin for a later sign-in — which is the whole point.
- [ ] On a match, or when the intent carries no marker: behave exactly as now.
- [ ] Apply the same rule to `storedAttribution`'s `dest`, which hands the
      destination to loby for the OAuth path and clears it the same way.

### Task 6: tests

- [ ] A mismatched sign-in builds no URL and leaves storage untouched.
- [ ] A matching sign-in builds the URL and clears, as today.
- [ ] An unmarked intent still hands off — absent means not bound.
- [ ] The OAuth `dest` path obeys the same rule.
- [ ] A missing/unreadable profile address does not throw and does not silently
      discard the intent.

---

## Rollout order

1. Tasks 1–4 (ui-team). Safe alone: with signin unchanged the destination is
   still handed away on a mismatch, so the scenario is only partly fixed — but
   nothing regresses.
2. Tasks 5–6 (signin). This completes it.
3. Verify the Goal scenario end to end on stage, in ONE tab: A→refused→armed,
   sign out, B→opens→cleared, sign out, B again→nothing.

Both repos deploy to the `huan` slot, which builds from this branch.

---

## Rollout checklist

- [ ] mail to A, click, sign in as B → nothing, and the intent survives
- [ ] sign out, sign in as A → checkout opens, coupon applied
- [ ] sign out, sign in as A again → **nothing** (single-use holds)
- [ ] a link with no marker opens for whoever signs in, once
- [ ] an account that cannot buy leaves the intent for a later attempt
- [ ] closing the tab discards it (sessionStorage lifetime unchanged)
- [ ] the OAuth path behaves the same as email/password

---

## Known gaps, stated rather than hidden

- **Retention is per tab.** sessionStorage dies with it, by design (Finding 4).
  A recipient who closes the tab re-clicks the CTA. Moving to localStorage would
  fix that and reintroduce a worse problem, so it is deliberately not done.
- **Retention is per origin, and the two are not synchronised.** The copy that
  matters is the one on the main domain, because that is where logout returns
  and where signin decides. An org-host copy left armed by a refusal simply dies
  with the tab; nothing reads it again.
- **Still advisory.** Anyone who learns the coupon can type it —
  `mkt_coupon_reserve` has no recipient allowlist, and `max_redemptions` is
  currently unlimited. This plan changes who gets walked into checkout, not who
  may redeem.
- **A wrong account can see the refusal repeatedly.** Signing in and out as B
  never consumes the intent, so B is refused every time and A can still claim
  it. That is intended, and worth knowing before it is reported as a loop.
