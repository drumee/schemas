# Carrying the Billing Destination Through OAuth — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A visitor who clicks the segment campaign CTA while signed out, and then signs in with **Google or Apple**, lands on the Team checkout screen with `EMAILMKT270826_2` already applied — the same place an email/password sign-in already takes them.

**Architecture:** Park the destination on `oauth_state`, beside `ref` and `utm_*`, and have the OAuth callback append it to the `home` URL it already builds. That is the one relay proven to survive the provider round trip, and the table exists for exactly this reason. Nothing new is invented: the destination becomes a fragment on the landing URL, and ui-team's existing `consume()` already reads a destination off the URL when storage has none.

**Tech stack:** MariaDB `yellow_page` patch, loby Node services (`google.js` / `apple.js` / `lib/loby.js`), the signin app's OAuth initiate call, ui-team's `billing-deep-link` (already done).

**Spec:** none separate — the investigation is in *Findings* below.

---

## What actually happens today

Measured on stage (drumee.in), not inferred:

```
1. Click CTA            https://drumee.in/-/huan/#/desk/billing?plan=team&…&promo=…
2. ui-team router       captureFromUrl() arms sessionStorage["drumee_billingDeepLink"]
                        — the deployed bundle DOES contain this (verified in
                          /-/huan/app/main-24876870….js)
3. signin plugin        rewrites the hash to #/welcome/signin  (destination gone from URL)
4. Google / Apple       full navigation OFF ORIGIN, then back to loby's callback
5. loby callback        home = `https://${res.domain}${endpoint_path}/`
                        → https://drumee.in/-/      ← built from scratch, server-side
6. account-created.html location.replace(home)
7. Desk boots at /-/    a DIFFERENT deploy slot from the one in step 1
```

---

## Finding 1 — the coupon is dropped before any of this matters

The deployed bundle contains `"promo"` **zero times**, on both slots:

```
                             /-/ (main)   /-/huan/
drumee_billingDeepLink       1            1
captureFromUrl               1            4
"promo"                      0            0
```

`parseParams` ships as `for (const k of ["plan", "cycle", "tab"])`. The coupon
never survives hop one, so "auto-fill the promo code" cannot work today for ANY
sign-in method, OAuth or not.

**Already fixed and already committed** — `feat/promo-tracking-send-email` in
ui-team adds `"promo"` to that allowlist. It is unpushed and undeployed. Nothing
in this plan works until that ships, which is why it is step 1 of the rollout
rather than a task here.

---

## Finding 2 — OAuth destroys every relay the deep link has, and the third one is the surprise

`billing-deep-link.js` has exactly two relays, and the callback defeats both:

| Relay | Why it survives an email/password sign-in | Why OAuth defeats it |
|---|---|---|
| `sessionStorage` | the reload stays in one tab on one origin | survives the provider bounce, but see Finding 3 |
| the URL (`#/desk/billing`, `?billing=1`) | `changeHost` sets `location.host`, which **keeps path and hash** | `home` is built from scratch: no path, no query, **no fragment** |

The URL relay is the one worth dwelling on. Its docblock explains that the
`?billing=1` ARG form exists to ride across a host switch "where per-origin
storage cannot follow". That reasoning is sound and the mechanism works — for
`changeHost`. It cannot work here, because a **server** builds the landing URL
and a fragment is never sent to a server in the first place. The module's own
fallback is structurally unable to help on this path.

---

## Finding 3 — sessionStorage probably DOES survive, and that is why this was hard to see

`res.domain` is `dd.name` from `session_login_with_oauth` — the account's own
domain. Checked on stage: for every `%huan%` account it is `drumee.in`, the same
origin the link was clicked on. sessionStorage is per-origin and survives a
navigation away and back within the same tab, so the armed intent is very likely
still readable at `https://drumee.in/-/`.

**Which means the failure is NOT simply "storage was lost", and a fix that only
hardens storage would be aimed at the wrong thing.** Two candidates remain, and
this plan could not narrow between them without a browser session on stage:

```js
_maybeOpenBillingDeepLink() {
  const preselect = billingDeepLink.consume();   // CLEARS storage
  if (!preselect) return false;
  if (!canUpgradePlan()) return false;           // consumed, then silently nothing
```

- **`canUpgradePlan()` refuses.** It needs the payment backend loaded AND org
  ownership. A freshly created OAuth account may satisfy neither at that instant.
  `consume()` has already destroyed the intent, so there is no second chance.
- **`_afterHomeSettled` never runs**, or runs before the desk module that owns
  the consumption is resolved, on the `/-/` slot.

**The fix in this plan makes both moot rather than choosing between them**: with
the destination on the landing URL, `consume()`'s URL branch answers even when
storage is empty, on whatever slot the visitor lands on, and the intent is no
longer destroyed by a single early read. Diagnosing which of the two fires is
still worth doing (Task 9) — but the feature does not wait on it.

---

## Finding 4 — the relay that already survives OAuth is one column short

`oauth_state` carries `ref` and `utm_source/medium/campaign/content` across the
provider bounce. Its own table comment states the reason in the words this
problem needs:

> "It has to live here because the callback is server-side and the visitor is
> bounced out to the provider in between, so **browser storage is unreachable**."

The pipeline is already built end to end:

```
signin  storedAttribution()  reads localStorage  →  google.initiate / apple.initiate
loby    initiate             INSERT oauth_state (ref, utm_*)
loby    callback             SELECT s.* → threads ref + utm onto the new profile
```

So the campaign markers from this very CTA **do** survive OAuth today. The
destination does not, only because nothing put it on that row. This plan adds
one column and the two ends that fill and read it.

**ONE COLUMN, NOT FOUR — and that differs from the utm precedent deliberately.**
That patch argued for four columns because "the analytics side reads these by
name (distribution_signups groups on campaign and source)". Nothing reads a
destination by name: it is opaque plumbing, written once and reassembled
verbatim into a URL. One column cannot drift out of step with itself, and a
future `&seats=5` costs nothing.

---

## Finding 5 — the landing template is a raw lodash interpolation

`lib/loby.js:27` imports `template` from **lodash**, and `account-created.html`
does:

```html
<script>location.replace('<%= home %>');</script>
```

In lodash `<%= %>` is the **RAW** delimiter — the reverse of EJS, where it is the
escaped one. `home` is currently server-built and safe. The moment it carries
anything derived from a request, a single `'` breaks out of that JS string
literal into script context, on a page that runs immediately after
authentication.

This is not hypothetical for this change: the whole point is to append
visitor-supplied content to `home`. **The destination must be validated against
an allowlist server-side before it reaches the template**, and it must be
validated as a *shape*, not merely escaped — a value that survives escaping can
still send the visitor somewhere the campaign never named.

---

## Global constraints

- **Signing in must never fail because of this.** The utm insert already models
  it: three nested INSERT fallbacks, so a database without the new column still
  signs people in. Copy that structure exactly — attribution and destinations
  are best-effort, authentication is not.
- **The destination is an allowlist, not a passthrough.** Only `#/desk/billing`
  with `plan` / `cycle` / `tab` / `promo`, each shape-checked. Anything else is
  dropped and the visitor lands on the ordinary home. This is what stops
  Finding 5 becoming an incident, and what stops the row becoming an open
  redirect vector.
- **No new endpoint.** initiate and callback already exist and already carry
  attribution; this rides on both.
- **ui-team needs no new consumption code.** `consume()` already ends with
  `urlWantsBilling() ? parseParams() : null`, so a landing URL carrying the
  fragment is read by the path that already serves signed-in visitors. Verify
  this rather than assume it (Task 8), but do not build a second reader.
- **Both providers, and all three callback outcomes.** google and apple are
  separate files with duplicated logic; a fix in one is half a fix. And the
  callback has three exits — existing sign-in (auto-redirect), new account
  (welcome card with a CTA link), and 2FA (bounce to the OTP screen). The
  destination has to survive all three or it works for some users only.

---

## File structure

```
schemas/
  yellow_page/patches/2026-08-27-oauth-state-dest.sql   NEW
  yellow_page/tables/oauth_state.sql                    MODIFIED  column + comment
  yellow_page/patches/manifest.txt                      MODIFIED
  yellow_page/patches/changelog.txt                     MODIFIED

loby/
  service/lib/loby.js        MODIFIED  _destFromInput, _sanitiseDest, dest → home
  service/google.js          MODIFIED  capture at initiate, apply at callback
  service/apple.js           MODIFIED  the same, both paths
  service/templates/account-created.html   MODIFIED  escape the interpolation
  offline/test/oauth-dest.test.js          NEW

signin/
  src/widgets/form/index.js  MODIFIED  storedAttribution() gains the destination

ui-team/
  (no change — the promo allowlist is already committed on
   feat/promo-tracking-send-email and only needs deploying)
```

---

# REPO 1 — schemas

### Task 1: the column

- [ ] `yellow_page/patches/2026-08-27-oauth-state-dest.sql`, modelled on
      `2026-08-24-oauth-state-utm.sql` — read that file first; this is the same
      problem for the same reason on the same table, and the header should say so.
- [ ] `ADD COLUMN IF NOT EXISTS dest varchar(255) ... DEFAULT NULL AFTER utm_content`,
      ascii / `ascii_general_ci` like its neighbours.
- [ ] The header must state: what it holds (a hash fragment to restore, e.g.
      `/desk/billing?plan=team&cycle=monthly&tab=checkout&promo=EMAILMKT270826_2`),
      why it is ONE column where utm_* are four (Finding 4), and that the value
      is validated at BOTH ends and never trusted from the row.
- [ ] Mirror the same column onto `yellow_page/tables/oauth_state.sql` so a fresh
      install matches a patched one, with the same comment.
- [ ] Manifest + changelog entries in the established format.
- [ ] Apply to stage and confirm: `bin/patch-from-file` then `SHOW COLUMNS FROM
      yp.oauth_state` — schema changes are not live on merge.

---

# REPO 2 — loby

### Task 2: capture at initiate

- [ ] In `lib/loby.js` add `_destFromInput()` beside `_utmFromInput()`, reading
      `this.input.get('dest')`.
- [ ] Add `_sanitiseDest(raw)` — the allowlist from Global constraints. It must
      return `null` for anything it does not fully recognise, and callers treat
      `null` as "no destination". Specifically: the path must be exactly
      `/desk/billing`; every param must be one of plan/cycle/tab/promo; each
      value must match its own shape (`plan` one of the known plan codes,
      `cycle` monthly|yearly, `tab` checkout, `promo` `[A-Za-z0-9_-]{1,64}`);
      the whole thing must be ≤255 chars and contain no quote, backslash,
      whitespace or angle bracket. Rebuild the string from the parsed parts
      rather than passing the input through — that is what makes it a shape
      check rather than an escaping exercise (Finding 5).
- [ ] In `google.js` and `apple.js` initiate: add `dest` to the INSERT, and
      **extend all three fallback tiers** so a database without the column still
      signs the visitor in. The existing utm fallback ladder is the template —
      do not collapse it.

### Task 3: read it back and put it on `home`

- [ ] The callback already destructures `ref, utm_*` off `s.*`; add `dest`.
- [ ] Re-run `_sanitiseDest` on the value READ BACK, not only on the way in. The
      row is data, and a value that reaches the template must have been checked
      by the code that builds the template's input. Cheap, and it is the
      difference between one guard and a guarded pipeline.
- [ ] Append as a fragment: `home = \`https://${res.domain}${endpoint_path}/#${dest}\``
      when a destination survives, unchanged otherwise.
- [ ] **All three exits.** Existing sign-in (`auto_redirect`), new account (the
      `home` CTA in the welcome card), and `otp_required` — that last one
      redirects to `#/welcome/signin?oauth_mfa=1&email=…`, so the destination has
      to ride through the OTP screen and be re-applied when the session
      finalises, or 2FA users get the plain desk. If that turns out to need
      signin-side work, say so rather than quietly leaving 2FA broken.

### Task 4: close the interpolation

- [ ] `account-created.html` renders `home` through lodash's RAW delimiter
      inside a JS string literal (Finding 5). Change it to the escaping
      delimiter, or better, emit the URL as a JSON-encoded value
      (`location.replace(<%= JSON.stringify(home) %>)`) so quoting is not a
      hand-maintained property.
- [ ] Check `otp-challenge.html` for the same shape — it interpolates `redirect`
      the same way.
- [ ] Leave a comment naming the lodash-vs-EJS delimiter inversion. It has
      already caused one defect in this codebase's email templates.

### Task 5: tests

- [ ] `offline/test/oauth-dest.test.js`, matching the existing offline test style.
- [ ] `_sanitiseDest` accepts the campaign's own destination and rebuilds it
      byte-for-byte; rejects a foreign path, an unknown param, a bad plan, a
      quote, a backslash, an over-length value, and a protocol-ish value.
- [ ] The INSERT ladder still has three tiers.
- [ ] `home` gains the fragment when a destination survives and is untouched
      when it does not.
- [ ] The templates no longer interpolate a URL raw into script context.

---

# REPO 3 — signin

### Task 6: forward the destination

- [ ] Extend `storedAttribution()` in `src/widgets/form/index.js`. It reads
      `drumee_utm` and `drumee_ref` from **localStorage**; the billing intent
      lives in **sessionStorage** under `drumee_billingDeepLink`, same origin,
      so it is readable from here.
- [ ] Build `dest` from that intent — `/desk/billing` plus whichever of
      plan/cycle/tab/promo it holds — and send it as one flat `dest` param, the
      shape initiate reads.
- [ ] Wrap in its own try/catch. The function's existing comments are explicit
      that private mode and corrupt values must degrade to "nothing stored";
      a destination must never be able to block a sign-in.
- [ ] Do NOT clear the sessionStorage copy here. It is the relay for the
      email/password path, which still works, and `consume()` owns clearing it.
- [ ] Update the docblock: it currently explains why attribution has to be sent;
      the destination is there for the same reason and the comment should say so
      rather than leaving a reader to wonder why a URL is in an attribution bag.

---

# REPO 4 — ui-team

### Task 7: nothing to build — verify and deploy

- [ ] Confirm `consume()` still ends with `urlWantsBilling() ? parseParams() : null`.
      That branch is what makes the whole plan work with no new consumption
      code, on whatever slot the visitor lands on.
- [ ] Confirm `PATH` (`/^#[/@]desk\/billing(?:[/?]|$)/i`) matches the fragment
      loby will produce, including the leading slash.
- [ ] The `promo` allowlist change is already committed on
      `feat/promo-tracking-send-email`. It must be pushed and deployed — see
      the rollout.

### Task 8: settle the two remaining candidates (diagnosis, not a fix)

- [ ] With the above deployed, if the billing screen still fails to open on some
      accounts, instrument `_maybeOpenBillingDeepLink` to log which branch
      returns false — `consume()` empty, or `canUpgradePlan()` refusing.
- [ ] If it is `canUpgradePlan()`, the ordering is its own defect worth fixing
      separately: `consume()` destroys the intent BEFORE the gate is asked, so a
      visitor who is briefly ineligible loses the destination permanently rather
      than getting it on the next boot.

---

## Rollout order

1. **ui-team's `promo` allowlist** — push and deploy `feat/promo-tracking-send-email`
   to every slot that serves campaign traffic. Nothing else in this plan is
   observable until this ships (Finding 1). Deploying it alone is already an
   improvement: email/password sign-ins get the coupon.
2. **Task 1** (the column), patched to stage.
3. **Tasks 2–5** (loby), deployed. Safe before signin ships: no caller sends
   `dest` yet, so every path behaves exactly as today.
4. **Task 6** (signin), deployed. This is the step that turns the feature on.
5. Verify on stage against a real Google account and a real Apple account.

Steps 2 and 3 must not be reordered: loby writing a column that does not exist
falls to its second fallback tier and silently drops every destination, which
looks exactly like the bug being fixed.

---

## Rollout checklist

- [ ] `yp.oauth_state` has `dest`
- [ ] Signed-out CTA click → Google → lands on Team checkout, coupon applied
- [ ] Same for Apple
- [ ] Same for a **2FA-enabled** account (the OTP exit)
- [ ] Same for a **brand-new** account (the welcome-card CTA exit)
- [ ] A visitor who signs in with no campaign link lands on the plain desk
- [ ] A hand-edited `dest` (foreign path, quote, `javascript:`) is dropped and
      the visitor still signs in
- [ ] Email/password sign-in still works — it uses the storage relay, untouched
- [ ] A database without the column still signs people in

---

## Known gaps, stated rather than hidden

- **The `canUpgradePlan()` ordering is not fixed here.** `consume()` clears the
  intent before the gate is asked, so an account that is briefly ineligible
  loses the destination for good. This plan routes around it by putting the
  destination on the URL, where it can be read again on a later boot — but the
  underlying order is still wrong and Task 8 is diagnosis, not a fix.
- **This plan could not reproduce the original failure.** No browser session on
  stage was available, so Finding 3's two candidates were narrowed by reading
  and by bundle inspection, not by observing the failure. The fix is aimed at a
  cause proven by code and by curl (Findings 1, 2, 4); if the billing screen
  still fails to open after step 4, Task 8 is where to look and the diagnosis is
  not complete.
- **The destination is capped at 255 characters** and silently truncated to
  nothing beyond that. Fine for this campaign; a future link with more params
  should widen the column rather than start compressing.
- **Nothing attributes the eventual purchase to the mail.** `utm_campaign`
  survives to the signup profile, but the coupon redemption row carries no
  campaign, so the Coupons page still cannot say which segment produced a
  redemption. Unchanged by this plan and noted in the segment-CTA plan too.
