# One Mail, One Offer — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One sent mail grants exactly one person one run at the discounted
checkout. Forwarding the mail must give the recipient's colleagues nothing. If
the addressed person cannot complete the flow — the link expired, the mail is
gone, they gave up half way — they can ask for it again, and asking again must
not multiply the offer.

**Tech stack:** `yp` schema (new table + 4 procs, 2 procs amended),
analytics-server (mint at send), ui-team (carry a token instead of a code),
server-team (claim + resend + one transactional template).

---

## What is actually exposed today

The CTA in `segment-a-101-contacts` / `segment-b-102-contacts` is built by
`_segmentCtaLink` and looks like this:

```
https://drumee.in/-/huan/#/desk/billing
  ?plan=team&cycle=monthly&tab=checkout&promo=EMAILMKT270826_2&for=cd8f5912
```

Three properties of that URL, all of them load-bearing:

1. **The coupon code travels in cleartext.** Anybody who receives, forwards,
   screenshots, or finds the mail in a shared inbox has the code. They do not
   even need the link — the promo field on the billing screen accepts typing.
2. **`for=` is a UX guard, not a control.** It is FNV-1a of the address, 8 hex
   characters, computed identically in `analytics-server._recipientTag` and
   `ui-team libs/billing-deep-link.recipientTag`. It is checked **only in the
   browser**, and it is trivially recomputed for any address you choose. Both
   source files say so in their own comments; this plan is the follow-through.
3. **`mkt_coupon_reserve` has no idea any of this happened.** It authorises on
   `code + email` alone.

### The exposure is narrower than it sounds — and that changes the design

`mkt_coupon_reserve` already enforces **1 email = 1 live deal**: no second
`pending|confirmed` row for the same address, ever, across every partner code.
So a single person cannot farm "a lot of promo" out of one mail no matter what
they do with the URL. That defence exists and works.

What is NOT bounded is the **number of people** one mail can serve. Forward the
101-contact mail to a 50-person team and every one of them redeems a 50% Team
discount that was budgeted for one recipient. Fifty addresses, fifty legitimate
"1 email = 1 live deal" grants. That is the real leak, and it is the one this
plan closes.

Stating it plainly matters, because it tells you what the work buys: not
"stops a determined person redeeming twice" (already handled), but **"a mail
that reaches 50 inboxes still only ever produces one deal."**

---

## The invariant

Everything below exists to serve one database constraint:

```sql
UNIQUE KEY `uni_campaign_email` (`campaign`, `email`)
```

**One grant row per address per campaign, forever.** A resend rotates the token
on that row. It cannot create a second one. "One mail = one flow" is therefore
a property of the schema, not of a code path somebody can forget to call.

---

## Finding 1 — the code must leave the URL

While `promo=EMAILMKT270826_2` is in the link, no server-side rule can help:
the value is public the moment the mail lands, and the promo input accepts it
by hand.

**The link carries an opaque grant token instead.** The coupon code is never in
the mail, never in browser history, never in a referrer. It is returned by the
server, over an authenticated call, only to the address the grant names.

```
#/desk/billing?plan=team&cycle=monthly&tab=checkout&g=<32 hex>
```

`plan`, `cycle` and `tab` stay — they are presentation, they are already
allowlisted by `parseParams`, and none of them is worth protecting. `promo` and
`for` are replaced by `g`.

## Finding 2 — the claim must be server-side, and it must be the thing that reveals the code

A client that already holds the code cannot be asked to protect it. Invert the
flow: the client holds a token that is worth nothing on its own, and asks the
server to exchange it.

```
client                        server-team                     yp
  |  payment.claim_offer(g)        |                            |
  |------------------------------->|  mkt_grant_claim(token,    |
  |                                |     email, uid)            |
  |                                |--------------------------->|
  |                                |   token found? not expired?|
  |                                |   not revoked?             |
  |                                |   grant.email == email?    |
  |                                |<---------------------------|
  |<-- {code, percent_off, ...}    |                            |
  |    or {status: OFFER_*}        |                            |
```

The signed-in address comes from `payment_get_payer(this.uid)` — the same
source `preview_coupon` and `checkout` already key on, so the three cannot
disagree about who is buying.

## Finding 3 — repeat claims by the right person are not abuse

**Recommended: the claim is idempotent for the address the grant names, and
refused for everyone else.**

The alternative — burn the grant on first open — turns "I opened checkout, went
to find my card, and came back" into a support ticket. It buys nothing: the
person is already the sole addressee, and `mkt_coupon_redemption` already caps
them at one deal. The property worth defending is *who*, not *how many times*.

A `single_use` flag on the grant row supports the strict reading if you want it
per campaign — one column, one `IF` in the proc:

| `single_use` | second claim by the addressed person |
|---|---|
| `0` (default) | OK — returns the same code again |
| `1` | `OFFER_SPENT` — they must use the resend path |

Set it to `0` for the segment campaigns. Everything else in this plan is
identical either way.

## Finding 4 — reserve must refuse a code nobody was granted

Until `mkt_coupon_reserve` knows about grants, the code is still bearer
credential: leak it once and it is redeemable by hand forever.

Add an opt-in gate on the **coupon**, not on the caller:

```sql
`requires_grant` TINYINT(1) NOT NULL DEFAULT 0
```

When set, `mkt_coupon_reserve` and `mkt_coupon_validate` both require a
`claimed` grant for `(code, email)` and answer `OFFER_NOT_GRANTED` otherwise.
Default `0`, so every existing partner code behaves exactly as it does now.
This is the server-side allowlist that both source files have been carrying a
TODO for.

**Both procs, in the same order.** Their own comments say the two must not
drift, or Apply green-lights what Proceed then refuses.

## Finding 5 — the resend, and why the mail is the *second* path

The user asks: if the flow fails, let them ask for the mail again. Two
different failures hide behind that:

| failure | who can act | what they need |
|---|---|---|
| grant expired, or they abandoned and came back after `single_use` burned it | **signed in already** | nothing mailed — re-issue in place, on the screen they are looking at |
| mail lost, deleted, never arrived | signed in, wants a copy | a transactional resend |
| cannot sign in as the addressed account at all | nobody | out of scope — this is account recovery, not offers |

So build **both**, and expect the first to carry the traffic:

- **In-session re-issue.** The billing screen, on `OFFER_EXPIRED` / `OFFER_SPENT`,
  shows *"This offer link has expired — get a new one"*. One click calls
  `payment.resend_offer`, which re-issues the grant and applies it immediately.
  No mail, no waiting, no deliverability risk.
- **Mailed resend.** The same call also sends a short transactional mail
  carrying the fresh link, so the offer exists somewhere the person can come
  back to.

**The resend mail is transactional, not the campaign creative.** It lives in
server-team as `service/templates/offer-resend.html` and goes out through the
existing `sendButlerMail`. Do not copy the 101/102 designs across repos: those
belong to marketing and change on marketing's schedule; this one says "here is
your link again" and should never change.

### Resend limits

All enforced inside `mkt_grant_resend`, so no caller can skip them:

| limit | default | reason |
|---|---|---|
| `max_sends` per grant | 3 | includes the original send |
| cooldown between sends | 900s | a click-happy user must not be able to mail-bomb their own inbox |
| grant TTL after re-issue | 30 days | matches the campaign window |
| refused when `status='revoked'` | — | the admin kill switch |

Past `max_sends` the proc answers `RESEND_LIMIT` and the UI says to contact
support. **Note the shape of this: the limit is on how many times the LINK is
re-sent, and it never affects how many deals exist. Even an unlimited resend
could not produce a second deal, because of the unique key and because
`mkt_coupon_redemption` caps the address.** The cooldown is there to protect
the inbox and the SMTP relay (which refuses more than 50 concurrent connections
per IP), not the discount budget.

## Finding 6 — links already in the wild

Mail has already gone to 101 + 102 addresses carrying `promo=` and `for=`.
Breaking them strands real people.

**Accept both forms for the length of the campaign:**

- `g=<token>` — the new path, everything above applies.
- `promo=` + `for=` — legacy. Keeps today's client-side `for=` check and
  today's reserve behaviour. `EMAILMKT270826_2` therefore keeps
  `requires_grant = 0` until the legacy window closes.

The legacy form **cannot be made safe** — the code is already public in 203
inboxes. Its exposure stays bounded by "1 email = 1 live deal" and by
`max_redemptions`, which the last change set to unlimited and which should be
reconsidered as part of this work. The clean answer is to mint a **new** code
for grant-gated sends (`requires_grant = 1`) and leave the old one to age out;
that is the recommendation.

---

## Tasks

### Phase 1 — schema (`/home/drumee/schemas`)

- [ ] `yellow_page/tables/mkt_mail_grant.sql`

  ```sql
  CREATE TABLE IF NOT EXISTS `mkt_mail_grant` (
    `id`          int(11) unsigned NOT NULL AUTO_INCREMENT,
    `campaign`    varchar(64)  CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    `coupon_id`   int(11) unsigned NOT NULL,
    `code`        varchar(64)  CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    `email`       varchar(255) NOT NULL,
    `uid`         varchar(16)  CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
    `token`       char(32)     CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    `status`      enum('issued','claimed','revoked') NOT NULL DEFAULT 'issued',
    `single_use`  tinyint(1)   NOT NULL DEFAULT 0,
    `send_count`  smallint(5) unsigned NOT NULL DEFAULT 1,
    `claim_count` smallint(5) unsigned NOT NULL DEFAULT 0,
    `issued_at`   int(11) unsigned NOT NULL,
    `expires_at`  int(11) unsigned NOT NULL,
    `last_sent_at`  int(11) unsigned NOT NULL,
    `first_claim_at` int(11) unsigned DEFAULT NULL,
    `last_claim_at`  int(11) unsigned DEFAULT NULL,
    `ctime`       int(11) unsigned NOT NULL,
    `mtime`       int(11) unsigned NOT NULL,
    PRIMARY KEY (`id`),
    -- THE invariant: one grant per address per campaign. A resend rotates
    -- `token` on this row; it can never make a second one.
    UNIQUE KEY `uni_campaign_email` (`campaign`, `email`),
    UNIQUE KEY `uni_token` (`token`),
    KEY `idx_code_email` (`code`, `email`, `status`),
    KEY `idx_campaign_status` (`campaign`, `status`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
  COMMENT='One mail = one offer. Per-recipient grant for a mailed coupon.';
  ```

  Collation note: `email` is `utf8mb4_general_ci` to match `mkt_coupon_redemption`
  and `directory`. Do not let it drift to `unicode_ci` — cross-schema joins throw
  ERROR 1267 when it does.

- [ ] `yellow_page/patches/2026-08-27-mkt-mail-grant.sql` — the `CREATE TABLE`
      plus `ALTER TABLE mkt_coupon ADD COLUMN requires_grant TINYINT(1) NOT NULL DEFAULT 0`.
      Mirror the column into `yellow_page/tables/mkt_coupon.sql`.
- [ ] `yellow_page/procedures/mkt/mkt_grant_issue.sql`
      `(_campaign, _code, _email, _uid, _ttl_sec, _single_use, _max_sends, _cooldown_sec)`
      → `INSERT … ON DUPLICATE KEY UPDATE` rotating `token`, resetting
      `expires_at`, bumping `send_count`. Refuses `RESEND_LIMIT` past
      `_max_sends` and `RESEND_COOLDOWN` inside the window. Resolves
      `coupon_id` from `_code` and answers `CODE_NOT_FOUND` if absent.
      Token: 32 hex from `SHA2(CONCAT(UUID(), RAND(), _email, UNIX_TIMESTAMP()), 256)`
      truncated — sufficient for a bearer with a 30-day life and a server-side
      identity check behind it.
- [ ] `yellow_page/procedures/mkt/mkt_grant_claim.sql`
      `(_token, _email, _uid)` → the coupon row joined to the grant, or one of
      `OFFER_NOT_FOUND` / `OFFER_EXPIRED` / `OFFER_REVOKED` / `OFFER_NOT_YOURS` /
      `OFFER_SPENT`. Sets `status='claimed'`, fills `uid` when null, bumps
      `claim_count`, stamps `first_claim_at` / `last_claim_at`.
      **`OFFER_NOT_YOURS` must not say whose it is** — the caller is not the
      addressee and does not get to learn the address.
- [ ] `yellow_page/procedures/mkt/mkt_grant_resend.sql` — thin wrapper over
      `mkt_grant_issue` keyed on `(_campaign, _email)`; refuses when no row
      exists (nothing to resend) and when `status='revoked'`.
- [ ] `yellow_page/procedures/mkt/mkt_grant_revoke.sql` `(_campaign, _email)` —
      the admin kill switch.
- [ ] Amend `mkt_coupon_reserve.sql`: after the `plan_scope` gate and **before**
      the "live deal" lookup, when `requires_grant = 1`, require a `claimed`
      grant for `(code, email)`; else `OFFER_NOT_GRANTED`.
- [ ] Amend `mkt_coupon_validate.sql` with the identical gate, in the identical
      position.
- [ ] Add all of the above to `patches/manifest.txt` in dependency order
      (table → alter → procs → amended procs).
- [ ] Verify in a scratch DB first. `mkt_coupon_*` and `promo_tracking` are
      **not provisioned on this box** — only `mkt_campaign_link` and
      `reward_claim` exist in the local `yp`. Create a scratch schema
      (`utf8mb4_general_ci`), load `mkt_coupon`, `mkt_coupon_redemption` and the
      new table, and drive the procs directly.
- [ ] Patch stage: `ssh huan@drumee.in`, then `bin/patch-from-file` per file.
      Diff each amended proc against the live one before overwriting —
      deployed procs drift from this repo, and `promo_tracking` is the proof
      (it exists on stage and in no `.sql` file here).

### Phase 2 — analytics-server (mint at send)

- [ ] `_issueGrant(email, campaign, code)` → calls `mkt_grant_issue`, returns
      the token. One call per address, inside the existing `personalise` hook —
      that hook already runs per recipient and is where `_recipientTag` lives.
- [ ] `_segmentCtaLink(link, campaign, token)` → emits `&g=<token>` in place of
      `&promo=…&for=…`. Keep `plan` / `cycle` / `tab`.
- [ ] **A send that cannot mint must not go out.** Today a missing tag silently
      degrades to an unbound link. With grants that would mail a CTA that opens
      an ordinary checkout with no discount — worse than not mailing, because
      the recipient reads it as the offer being withdrawn. Collect mint
      failures and report them beside the delivery failures the send already
      returns.
- [ ] Delete `_recipientTag` **only after** the legacy window closes. It is
      still needed for links already sent.
- [ ] Grants give these campaigns a per-recipient row for the first time
      (`tracked: false` today). A follow-up can surface issued / claimed counts
      on the promo card — out of scope here, noted so the table is not
      redesigned for it later.

### Phase 3 — ui-team (carry the token)

- [ ] `libs/billing-deep-link.js`: add `g` to the `parseParams` allowlist.
      Keep `promo` and `for` for the legacy window.
- [ ] `isForCurrentUser` keeps working on `for` and is bypassed when `g` is
      present — with a grant the **server** decides, and asking twice from two
      sources is exactly the failure the retention work just removed.
- [ ] Billing widget `_applyDeepLink` / `_autoApplyDeepLinkPromo`: when the
      preselect carries `g`, call `payment.claim_offer` first, seed
      `state.checkout.promoCode` from the returned code, then run the existing
      apply path unchanged.
- [ ] Render the refusals. `OFFER_EXPIRED` and `OFFER_SPENT` get the *"get a new
      one"* button; `OFFER_NOT_YOURS` gets a flat "this offer was sent to a
      different account" with no address in it; `OFFER_REVOKED` and
      `OFFER_NOT_FOUND` get a generic failure. New `locale/en.json` keys.
- [ ] The deep link is consumed on a **successful claim only**. A refusal keeps
      it, exactly as the retention work established — the "get a new one"
      button needs the campaign still in hand.

### Phase 4 — server-team (claim + resend)

- [ ] `payment.claim_offer` — `g` in, offer shape out. Identity from
      `payment_get_payer(this.uid)`, never from the request body.
- [ ] `payment.resend_offer` — no token in, because the caller is asking
      precisely because theirs does not work. Keyed on the signed-in address +
      campaign. Calls `mkt_grant_resend`, applies the new grant in-session, and
      sends the mail.
- [ ] `service/templates/offer-resend.html` — short, transactional, one button.
      Through `sendButlerMail`. Batch/pool if this is ever driven in bulk: the
      relay refuses >50 concurrent connections per IP.
- [ ] `acl/payment.json` — both, `"scope": "hub"`, `"permission": {"src": "owner"}`,
      matching `preview_coupon`. `claim_offer` takes a required `g`;
      `resend_offer` takes an optional `campaign` defaulting to the segment one.
- [ ] Do not add the `log` flag unless you want `services_log` rows for every
      claim. (You may: it is the sanctioned tracking hook, and claim volume is
      low.)

### Phase 5 — tests

- [ ] **Procs, in a scratch DB.** The invariant first: issue twice for the same
      `(campaign, email)` and assert one row and a rotated token. Then claim by
      the wrong address (`OFFER_NOT_YOURS`, and assert the response carries no
      address), claim past `expires_at`, claim a revoked grant, second claim
      with `single_use` both ways, `RESEND_LIMIT`, `RESEND_COOLDOWN`.
- [ ] **The reserve gate.** `requires_grant = 1` + no grant → `OFFER_NOT_GRANTED`.
      `requires_grant = 0` → byte-identical behaviour to today. Run
      `mkt_coupon_validate` against every one of those cases and assert the two
      agree — that is the drift the procs' own comments warn about.
- [ ] **analytics-server**: the CTA carries `g` and carries neither `promo` nor
      `for`; a mint failure blocks that address and is reported.
- [ ] **ui-team**: `g` survives `parseParams`; a claim refusal keeps the deep
      link armed; a successful claim consumes it. Extend
      `tests/billing-deep-link-promo.test.js`.
- [ ] Mutation-check every new assertion. Break the thing it names, watch it
      fail, restore. An assertion that passes against the broken code is worse
      than none.

### Phase 6 — rollout

- [ ] Mint a **new** code for grant-gated sends with `requires_grant = 1`.
      Leave `EMAILMKT270826_2` at `0` so the 203 links already sent keep working.
- [ ] Reconsider `max_redemptions` on `EMAILMKT270826_2`. It is currently
      unlimited, and for the legacy code — whose value is public in 203 inboxes
      — a hard cap is the only remaining bound on total spend.
- [ ] Deploy order: **schema → server-team → ui-team → analytics-server.**
      analytics-server is last because it is the only one that mints links, and
      a link must never reach an inbox before the code that can claim it is
      live.
- [ ] After the campaign window, drop `promo`/`for` from `parseParams`, delete
      `_recipientTag` on both sides, and set `requires_grant = 1` everywhere.

---

## Explicitly out of scope

- **Unauthenticated resend.** A public "mail me my offer" form is a mail-bomb
  gun pointed at any address someone types. The resend here requires a signed-in
  session, which is why it can be generous about limits.
- **Account recovery.** Someone who cannot sign in as the addressed account
  cannot be helped by an offer endpoint.
- **Making the legacy link safe.** `EMAILMKT270826_2` is public in 203 inboxes.
  It can be capped and it can be retired. It cannot be un-leaked.
