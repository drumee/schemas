# Design: 2FA for OAuth (Google / Apple) login

Date: 2026-06-18
Status: Approved pending review

## Goal

When a user who has **email-2FA enabled** (`profile.otp === 'email'`) signs in via
"Sign in with Google" or "Sign in with Apple", require the same email OTP that a
password login already requires. The challenge reuses the existing `dtk_otp`
widget and the provider-agnostic `session_login_otp` verification path. Brand-new
OAuth sign-ups (created with `otp: 0`) are never challenged.

### Decisions (confirmed with user)

1. **Trigger:** Reuse the existing per-user 2FA flag (`profile.otp === 'email'` /
   `mfa`). No new OAuth-only setting; no always-on forcing.
2. **OTP UI:** Reuse the signin SPA's `dtk_otp` widget. The loby callback redirects
   the browser back to the signin app in a pending state.
3. **Method:** Email OTP only (matches the working `_send2faOtpEmail` path).
   SMS/passkey are out of scope.

## Background — the two existing flows

### Password 2FA (works today)
- `yp.login` -> `session.signin(vars)`. A `session.send_otp` override checks
  `profile.otp === 'email'` and calls `_send2faOtpEmail(user)`
  (`server-team/service/yp.js`), which mints an OTP via `otp_create(uid, token)`,
  emails the code using `service/templates/otp.html`, and returns `{ secret }`.
- The signin response carries `secret` (no full session). The SPA renders
  `dtk_otp` and submits `{ uid, code, secret }` to `yp.login_top`
  (`signin/src/widgets/router/index.js`, the `verify-signin-otp` handler).
- `yp.login_top` -> `session_login_otp(uid, code, secret, sid)`
  (`yellow_page/procedures/session/session_login_otp.sql`) verifies the code
  against the `otp` table and promotes `cookie.status` to `ok`.

### OAuth (no 2FA today)
- SPA -> `google.initiate` / `apple.initiate`
  (`loby/service/google.js`, `apple.js`) returns `{ status:'prompt', authUrl }`
  and stores an `oauth_state` row keyed to the signin session id.
- `location.href = authUrl` -> provider -> loby `*.callback`.
- `callback()` -> `handleOAuthCallback(profile)` (`loby/service/lib/loby.js`).
- `session_login_with_oauth(provider, provider_id, email, session_id, domain)`
  (`yellow_page/procedures/session/session_login_with_oauth.sql`) finds/links the
  user and **unconditionally** sets `cookie.status='ok'`, returning the full
  session.
- `callback()` -> `sendHtml(...)` sets the authorized session cookie
  (`setAuthorization`) and returns an HTML page that redirects to the desk.

## Key insight

`session_login_otp(key, code, secret, cid)` finalizes **whatever pending cookie**
matches a valid OTP — it is agnostic to how the session was started. So adding
2FA to OAuth requires only:

1. Leave the OAuth session **pending** instead of `ok` when 2FA is required.
2. Mint an OTP row and email the code.
3. Hand off to the SPA's `dtk_otp` widget, which finalizes the pending cookie.

The OTP secret never needs to leave the server (an improvement over the password
flow, which returns the secret to client JS).

## Target flow (existing user with email-2FA, via Google/Apple)

1. SPA -> `google/apple.initiate` -> redirect to provider. *(unchanged)*
2. Provider -> loby `*.callback` -> `handleOAuthCallback()`.
3. `session_login_with_oauth` resolves the user, sees
   `JSON_VALUE(profile,'$.otp') = 'email'`, sets `cookie.status='otp_pending'`
   (NOT `ok`), and returns `error_code = 'otp_required'` plus `id` and `email`.
4. loby, on `otp_required`:
   - `otp_create(uid, token)` -> `{ code, secret }`.
   - Emails the code (same `otp.html` template + `Messenger` as
     `_send2faOtpEmail`; display-name From `"Drumee" <butler@...>`).
   - Returns an HTML page that **redirects the browser to the signin SPA** in a
     pending state, e.g. `https://{domain}/#/welcome/signin?oauth_mfa=1&email=...`.
   - Does **not** call `sendHtml` / `setAuthorization` — the session stays
     pending. The secret stays server-side.
5. SPA detects `oauth_mfa=1` on load -> renders `dtk_otp` -> user enters the
   6-digit code -> calls `oauth.verify_otp` with `{ code }` (no client secret).
6. `oauth.verify_otp` resolves the pending cookie from `input.sid()`, reads the
   server-side secret for that uid, calls
   `session_login_otp(uid, code, secret, sid)`. On success: `cookie.status='ok'`,
   `setAuthorization`, return session -> SPA reloads -> signed in.
7. Resend -> `oauth.resend_otp` regenerates + re-emails for the pending session.

## Changes by repo

### schemas (this repo) — requires DB patching across all YP instances
- `yellow_page/procedures/session/session_login_with_oauth.sql`
  - After STEP 3 resolves `_profile`, before the final `ok` select, branch on
    `JSON_VALUE(_profile,'$.otp') = 'email'`:
    - Set `cookie.status = 'otp_pending'` (do NOT set `ok`).
    - Return a result row carrying `error_code = 'otp_required'`, plus `id`
      (uid) and `email`, so loby can mint/email the OTP.
  - The `oauth_user_not_found` (new user) and `oauth_not_linked` branches are
    unchanged. Auto-linked existing accounts with 2FA are covered automatically
    because the branch keys off the resolved profile.
- Patch via `bin/patch-from-file yellow_page/procedures/session/session_login_with_oauth.sql yellow_page`,
  then sweep all YP instances. (Schema change != live until patched.)

### loby
- `service/lib/loby.js`
  - `handleOAuthCallback`: handle the new `otp_required` result — mint OTP
    (`otp_create`), email it, and return a marker `{ status:'otp_required',
    email, id, provider }`.
  - Add a `sendOtpEmail(user)` helper (port of `_send2faOtpEmail`).
- `service/google.js` + `service/apple.js`
  - `callback()`: when `handleOAuthCallback` returns `otp_required`, redirect the
    browser to the signin SPA pending route instead of `sendHtml`.
- New `service/oauth.js` + `acl/oauth.json` (provider-agnostic; keyed off the
  pending session):
  - `verify_otp({ code })`: resolve pending cookie uid from `input.sid()`, read
    secret, call `session_login_otp`, set authorization on success, return
    session.
  - `resend_otp()`: re-mint + re-email for the pending session.
- `service/templates/otp.html`: copy of the server-team template (or a shared
  template). See open question below.

### signin SPA (`src/widgets/form` + `src/widgets/router`)
- `src/widgets/form/index.js`: on load (`initialize`/`onDomRefresh`), detect the
  `oauth_mfa=1` (+ `email`) marker and drive the existing `verify-signin-otp`
  path, but pointed at `SERVICE.oauth.verify_otp` with an OAuth payload
  (no client-side secret).
- `src/widgets/router/index.js`: extend the `verify-signin-otp` handler to accept
  an api/method override so it can target `SERVICE.oauth.verify_otp`; wire the
  resend action to `SERVICE.oauth.resend_otp`.
- `SERVICE.oauth.*` resolves from the platform services (same mechanism as
  `SERVICE.google.*` / `SERVICE.apple.*`).

## Security / edge cases

- OTP secret never leaves the server (stronger than the password flow).
- OTP rows self-expire after 10 minutes (`session_login_otp` deletes stale rows).
- Abandoned challenge -> pending cookie never promoted to `ok`; harmless and
  expires.
- Brand-new OAuth signups (`otp: 0`) are not challenged.
- Existing password accounts auto-linked to a provider on first OAuth use are
  still challenged (branch keys off the resolved profile).
- Pending cookie binding: `oauth_state.session_id` == the signin session ==
  `input.sid()` after the redirect, because the pending HTML does NOT overwrite
  the session authorization. The SPA verify call therefore resolves the correct
  pending cookie. **Verify during implementation** that the signin session cookie
  survives the provider round-trip.

## Open implementation choice (non-blocking)

The 2FA email send in loby can either (a) **duplicate** the `otp.html` template +
Messenger logic from server-team, or (b) call a small shared private service.
Default: **(a) duplicate the template into loby**, matching how loby already
replicates account-creation logic. Flag for revisit if a shared template is
preferred.

## Out of scope

- SMS and passkey 2FA methods.
- Changing the per-user 2FA enable/disable admin UI (already exists).
- Drive-migration OAuth token handling (untouched).
