# Verify by Email — Design Spec

**Date:** 2026-06-08
**Status:** Approved for planning
**Repos touched:** `/home/drumee/schemas` (SQL), `/home/drumee/loby` (service + email template), `/home/drumee/signup` (frontend widgets)

## Summary

Add an email-verification step to signup using a **token verification link** (not an OTP
code). After a user signs up, their account is created in an **unverified** state, they see a
"Check your inbox" screen, and they receive an email with a "Verify Email Address" button
linking to `https://<domain>/verify?token=<secret>`. Clicking the link validates the token,
flips the account to verified, and shows an "Email confirmed" screen with a "Back to Drumee" CTA.

Source of truth for UI/copy: Figma file `g5V3PjhNMf5bHlsHMvV17w`
- S1 "Check your inbox": node `1706:33729`
- S2 "Email confirmed": node `1709:591`
- Email template: node `1706:26807`

## Decisions (confirmed)

1. **Mechanism: token link** — matches all three Figma frames. The existing 6-digit OTP path in
   loby is dead/divergent and is **left untouched** (see Out of Scope) — the new link flow is
   added alongside, and the active signup path is switched to use it.
2. **Account state: create unverified, link activates** — account is created immediately on
   signup with `registration_verified=0`; the email staged in `unverified_email`. Clicking the
   verify link sets `registration_verified=1` and promotes `unverified_email → email`. "Back to
   Drumee" logs the user in. ("You can now access all Drumee features" reflects features being
   gated on `registration_verified` until then.)
3. **Token expiry: 24 hours** — matches the email's security note.

## Existing infrastructure to REUSE (do not rebuild)

- **`verification` table** — `/home/drumee/schemas/yellow_page/tables/verification.sql`
  (`sys_id`, `drumate_id`, `token` UNIQUE, `ctime`).
- **`drumate_verify_email(_id, _email_hash, _token)`** —
  `/home/drumee/schemas/yellow_page/procedures/drumate/verify-email.sql`. Reads the latest token
  for the drumate, compares the submitted token and `sha2(unverified_email,512)`; on match sets
  `email = unverified_email`, `registration_verified = 1`, clears `unverified_email`. **This is
  the verify side, already done.**
- **`drumate` columns** `registration_verified INT DEFAULT 0`, `unverified_email VARCHAR(255)` —
  `/home/drumee/schemas/yellow_page/tables/tables.sql:295`.
- **`forgot_password` flow** (`validation_code` + `sha2(uuid())` token + emailed reset link) — the
  reference pattern for token generation, link routing, and email delivery. The verify-email link
  must be **served/routed the same way the password-reset link already is.**

## Gaps to BUILD

### 1. Schema — `/home/drumee/schemas/yellow_page/procedures/drumate/`

- **New: `drumate_set_verification_token(_id, _email)`** (one file, one proc) — the missing
  counterpart to `drumate_verify_email`. Generates a `sha2(uuid())` token, `INSERT INTO
  verification (drumate_id, token, ctime)`, sets `drumate.unverified_email = _email`, leaves
  `registration_verified = 0`. Returns the token (the link `secret`).
- **Modify `drumate_verify_email`** — add 24h expiry check (`UNIX_TIMESTAMP() - ctime <= 86400`)
  so expired tokens fail. Keep the rest of the logic.
- **Signup creation path** — ensure a freshly created account lands with
  `registration_verified = 0` and the email staged in `unverified_email` (so
  `drumate_verify_email`'s email-hash comparison succeeds). Confirm against `drumate_create`
  during planning; add a minimal proc/patch if `drumate_create` always sets a confirmed email.
- Patching: apply each new/changed `.sql` per `CLAUDE.md` (`bin/patch-from-file`) to all relevant
  instances; one routine per file.

### 2. loby service — `/home/drumee/loby/service/signup.js` + `acl/signup.json`

- **`save_info` / `create_account`** — on account creation, call `drumate_set_verification_token`
  and send the **link** email (new template below) instead of the OTP email. (OTP generation left
  in place but no longer the active mechanism.)
- **New `verify_email({token, email_hash})`** service method — calls `drumate_verify_email`,
  returns `{ verified: 1 }` or an error. Add to `acl/signup.json` (anonymous / public-api), same
  shape as existing entries. Replaces the dead `verify_otp` entry conceptually (verify_otp left in
  place per scope decision).
- **New `resend_verification()`** service method — regenerates the token and re-sends the link
  email; backs S1's "Resend email". Add to `acl/signup.json`.

### 3. Email template — `/home/drumee/loby/service/templates/verify-email.html`

New template matching Figma node `1706:26807`:
- Purple header band with Drumee logo.
- "Verify Your Email Address" / "Thank you for registering with Drumee".
- Greeting + body copy.
- **Verify Email Address** button → `https://<main_domain>/verify?token=<secret>`.
- "Or copy and paste this link" fallback URL.
- Security note: "This verification link will expire in 24 hours…".
- "Need Help?" support block + footer (social links, copyright, drumee.org / Privacy Policy).
- Rendered via the existing `Messenger.renderFrom(tpl, data)` mechanism.

### 4. Frontend — `/home/drumee/signup/src/`

- **S1 "Check your inbox" widget** (Figma `1706:33729`) — envelope icon, title "Check your
  inbox", "We sent a verification link to {email}", **Resend email** button (calls
  `resend_verification`), **Cancel** button (aborts/returns). Shown by `signup_router` after the
  form step. Register the widget slot in `src/seeds.js`.
- **S2 "Email confirmed" widget/state** (Figma `1709:591`) — served at the `/verify` landing
  route; on load calls `verify_email({token})` (token read from the URL). On success: green
  check icon, "Email confirmed", "Your email has been verified. You can now access all Drumee
  features.", **Back to Drumee** CTA (login / navigate to app). On failure (bad/expired token):
  error state with a resend affordance.
- **Locale** — add link-flow strings to `src/locale/en.json` (e.g. `CHECK_YOUR_INBOX`,
  `WE_SENT_LINK_TO`, `RESEND_EMAIL`, `EMAIL_CONFIRMED`, `EMAIL_VERIFIED_BODY`, `BACK_TO_DRUMEE`).
  The existing code-entry strings (`ENTER_VERIFICATION_CODE`, `VALIDATION_SENT_TO`, …) are not
  reused.
- **Routing** — the `/verify?token=` landing must mirror the existing password-reset link
  mechanism. Exact route/module to be pinned down in the plan by reading that flow.

## Data flow

```
Signup form (email, password)
  └─> loby create_account
        ├─ drumate_create (registration_verified=0, unverified_email=email)
        ├─ drumate_set_verification_token(id, email)  -> secret
        └─ send verify-email.html with link /verify?token=<secret>
  └─> S1 "Check your inbox"  (Resend email -> resend_verification)

User clicks link in email -> /verify?token=<secret>
  └─> S2 loads -> verify_email({ token, email_hash })
        └─ drumate_verify_email -> registration_verified=1, email=unverified_email
  └─> S2 "Email confirmed" -> Back to Drumee (login)
```

## Error handling

- Invalid/expired token: `drumate_verify_email` returns `updated=0`; S2 shows an error with a
  resend path.
- Resend: regenerate token (old token superseded; `verification` keyed by latest `ctime`).
- Email send failure: surfaced via existing `Messenger`/`exception.email` handler; S1 still shown,
  user can resend.

## Out of scope (follow-up)

- Removing the dead OTP path (`save_signup_info` 6-digit `otp`, `signup_data.otp` column,
  `verify_otp` ACL entry, OTP `onboarding.js` template). Retained as dead code; tracked for a
  later cleanup.
- Rate-limiting / throttling of "Resend email" beyond what existing infra provides.

## Testing

- Schema: unit-check `drumate_set_verification_token` inserts token + stages email; round-trip
  with `drumate_verify_email` (valid token → verified=1; wrong token → 0; expired → 0).
- Service: `verify_email` happy path + bad/expired token; `resend_verification` regenerates.
- Frontend: S1 renders email + resend; S2 verifies on load and renders confirmed/error states.
- Manual: full signup → inbox → click link → confirmed → login.
