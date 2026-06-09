# Verify by Email Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add token-link email verification to signup — after signing up, the user gets an email with a verify link, clicking it confirms their account and shows an "Email confirmed" screen.

**Architecture:** Reuse the existing `verification` table and `registration_verified`/`unverified_email` columns on `drumate`. A new SQL proc mints a token + stages the email; a new token-only verify proc promotes the email and flips the verified flag. loby's signup service emails the link and exposes `verify_email`/`resend_verification`. The signup frontend gets two new widgets (S1 "Check your inbox", S2 "Email confirmed") routed under `#/welcome/...`.

**Tech Stack:** MariaDB stored procedures (patched via `bin/patch-from-file`), Node.js loby services (`@drumee/server-essentials`, lodash email templates), Drumee LETC widget frontend (webpack).

**No automated test framework exists in any of the three repos.** Verification steps use direct DB queries (`mysql` over the unix socket), service smoke checks, and a manual build/run — there is no `jest`/`mocha` to run. This matches the codebase.

**Repos & roots:**
- Schema: `/home/drumee/schemas`
- loby service: `/home/drumee/loby`
- signup frontend: `/home/drumee/signup`

**Reference design:** `docs/superpowers/specs/2026-06-08-verify-by-email-design.md`

---

## File Structure

**Create:**
- `/home/drumee/schemas/yellow_page/procedures/drumate/set-verification-token.sql` — mints token, stages `unverified_email`
- `/home/drumee/schemas/yellow_page/procedures/drumate/verify-email-token.sql` — token-only verify (promotes email, sets `registration_verified=1`)
- `/home/drumee/loby/service/templates/verify-email.html` — the verification email (lodash `<%= %>` template)
- `/home/drumee/signup/src/widgets/check-inbox/index.js` + `skeleton/index.js` + `skin/index.scss` — S1
- `/home/drumee/signup/src/widgets/verified/index.js` + `skeleton/index.js` + `skin/index.scss` — S2

**Modify:**
- `/home/drumee/loby/service/signup.js` — generate token + send link on `create_account`; add `verify_email`, `resend_verification`
- `/home/drumee/loby/acl/signup.json` — add `verify_email`, `resend_verification` entries
- `/home/drumee/signup/src/seeds.js` — register the two new widgets
- `/home/drumee/signup/src/widgets/router/index.js` — route to S1 after signup, route to S2 on verify link
- `/home/drumee/signup/src/widgets/form/index.js` — on `create_account` success, show S1 instead of `location.reload()`
- `/home/drumee/signup/src/locale/en.json` — link-flow strings

---

## Task 1: SQL — mint verification token + stage email

**Files:**
- Create: `/home/drumee/schemas/yellow_page/procedures/drumate/set-verification-token.sql`

- [ ] **Step 1: Write the procedure**

The `verification` table is `(sys_id AUTO, drumate_id VARBINARY(16), token VARCHAR(255) UNIQUE, ctime INT)`. Match `forgot_password`'s token style (`sha2(uuid(), 224)`). Clear any prior token for this drumate so only the latest is valid.

```sql
DELIMITER $

-- =========================================================
-- drumate_set_verification_token
-- Mints a fresh email-verification token for a drumate and
-- stages the address in unverified_email. Returns the token
-- (used as the ?token= secret in the verify link).
-- =========================================================
DROP PROCEDURE IF EXISTS `drumate_set_verification_token`$
CREATE PROCEDURE `drumate_set_verification_token`(
  IN _id    VARBINARY(16),
  IN _email VARCHAR(255)
)
BEGIN
  DECLARE _token VARCHAR(255);

  SELECT sha2(uuid(), 224) INTO _token;

  DELETE FROM verification WHERE drumate_id = _id;
  INSERT INTO verification (drumate_id, token, ctime)
    VALUES (_id, _token, UNIX_TIMESTAMP());

  UPDATE drumate SET unverified_email = _email WHERE id = _id;

  SELECT _token AS token;
END $

DELIMITER ;
```

- [ ] **Step 2: Apply the procedure to the YP database**

Run:
```bash
cd /home/drumee/schemas && bin/patch-from-file yellow_page/procedures/drumate/set-verification-token.sql yellow_page
```
Expected: success output, no SQL error.

- [ ] **Step 3: Verify it mints a token and stages the email**

Pick any existing drumate id for a throwaway check. Run:
```bash
mysql -S /var/run/mysqld/mysqld.sock yp -e "
  SET @id := (SELECT id FROM drumate LIMIT 1);
  CALL drumate_set_verification_token(@id, 'plan-test@drumee.io');
  SELECT v.token, d.unverified_email
    FROM verification v JOIN drumate d ON d.id = v.drumate_id
    WHERE v.drumate_id = @id;
  DELETE FROM verification WHERE drumate_id = @id;
  UPDATE drumate SET unverified_email = NULL WHERE id = @id;"
```
Expected: one row with a 56-char hex `token` and `unverified_email = plan-test@drumee.io`. (Last two statements clean up the throwaway data.)

- [ ] **Step 4: Commit**

```bash
cd /home/drumee/schemas
git add yellow_page/procedures/drumate/set-verification-token.sql
git commit -m "feat(yp): add drumate_set_verification_token for email verify links"
```

---

## Task 2: SQL — token-only verify proc

**Files:**
- Create: `/home/drumee/schemas/yellow_page/procedures/drumate/verify-email-token.sql`

The existing `drumate_verify_email` requires an `_email_hash` arg the token link doesn't carry, so add a token-only sibling. It promotes `unverified_email → email` (column + `profile.$.email`), sets `registration_verified=1`, and enforces a 24h expiry.

- [ ] **Step 1: Write the procedure**

```sql
DELIMITER $

-- =========================================================
-- drumate_verify_email_token
-- Verifies a signup email using only the token from the
-- verification link. On success promotes unverified_email to
-- the live email and flips registration_verified. 24h expiry.
-- =========================================================
DROP PROCEDURE IF EXISTS `drumate_verify_email_token`$
CREATE PROCEDURE `drumate_verify_email_token`(
  IN _token VARCHAR(255)
)
BEGIN
  DECLARE _id    VARBINARY(16) DEFAULT NULL;
  DECLARE _ctime INT(11) DEFAULT 0;

  SELECT drumate_id, ctime INTO _id, _ctime
    FROM verification WHERE token = _token LIMIT 1;

  -- NOTE: drumate.email is a VIRTUAL GENERATED column (from profile.$.email)
  -- on live instances, so it cannot be assigned directly. Update profile only;
  -- the generated email column follows.
  IF _id IS NOT NULL AND (UNIX_TIMESTAMP() - _ctime) <= 86400 THEN
    UPDATE drumate
      SET profile = JSON_SET(profile, "$.email", IFNULL(unverified_email, JSON_VALUE(profile, "$.email"))),
          registration_verified = 1,
          unverified_email = NULL
      WHERE id = _id;
    DELETE FROM verification WHERE drumate_id = _id;
    SELECT 1 AS verified;
  ELSE
    SELECT 0 AS verified;
  END IF;
END $

DELIMITER ;
```

- [ ] **Step 2: Apply to the YP database**

Run:
```bash
cd /home/drumee/schemas && bin/patch-from-file yellow_page/procedures/drumate/verify-email-token.sql yellow_page
```
Expected: success, no SQL error.

- [ ] **Step 3: Verify round-trip (mint → verify → flag set)**

Run:
```bash
mysql -S /var/run/mysqld/mysqld.sock yp -e "
  SET @id := (SELECT id FROM drumate LIMIT 1);
  SET @old_email := (SELECT email FROM drumate WHERE id=@id);
  SET @old_rv := (SELECT registration_verified FROM drumate WHERE id=@id);
  CALL drumate_set_verification_token(@id, 'plan-roundtrip@drumee.io');
  SET @tok := (SELECT token FROM verification WHERE drumate_id=@id);
  CALL drumate_verify_email_token(@tok);
  SELECT registration_verified, email FROM drumate WHERE id=@id;
  -- restore
  UPDATE drumate SET email=@old_email, registration_verified=@old_rv,
    profile=JSON_SET(profile,'\$.email',@old_email), unverified_email=NULL WHERE id=@id;
  DELETE FROM verification WHERE drumate_id=@id;"
```
Expected: result row shows `registration_verified = 1` and `email = plan-roundtrip@drumee.io`. (Trailing statements restore the row.)

- [ ] **Step 4: Verify a bad token returns 0**

Run:
```bash
mysql -S /var/run/mysqld/mysqld.sock yp -e "CALL drumate_verify_email_token('not-a-real-token');"
```
Expected: single row `verified = 0`.

- [ ] **Step 5: Commit**

```bash
cd /home/drumee/schemas
git add yellow_page/procedures/drumate/verify-email-token.sql
git commit -m "feat(yp): add drumate_verify_email_token (token-only signup verify)"
```

---

## Task 3: Email template — verify-email.html

**Files:**
- Create: `/home/drumee/loby/service/templates/verify-email.html`

Mirror `service/templates/otp.html` structure (purple header, Geist fonts, 600px table, footer) but with a CTA button + fallback link + security note + support block, matching Figma node `1706:26807`. Uses lodash `<%= %>` delimiters (confirmed via `Messenger.renderFrom`).

- [ ] **Step 1: Write the template**

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="x-apple-disable-message-reformatting">
  <title><%= heading %></title>
</head>
<body style="margin:0;padding:0;background:#f2f2f7;-webkit-font-smoothing:antialiased;font-family:'Geist','SF Pro Display',-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="width:100%;background:#f2f2f7;">
    <tr>
      <td align="center" style="padding:20px 8px;text-align:center;">
        <table role="presentation" width="600" cellpadding="0" cellspacing="0" border="0" align="center" style="width:600px;max-width:100%;margin:0 auto;background:#fff;border-radius:8px;overflow:hidden;">

          <!-- Header -->
          <tr>
            <td bgcolor="#433cc5" align="center" style="padding:24px;background:#433cc5;text-align:center;border-radius:8px 8px 0 0;">
              <img src="https://content.app.drumee.com/icons/logo.png" width="170" height="36" alt="Drumee" style="display:block;border:0;outline:0;text-decoration:none;margin:0 auto;">
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:32px;" align="center">
              <h1 style="margin:0 0 8px 0;text-align:center;font-weight:600;font-size:24px;line-height:1.2;color:#282538;"><%= heading %></h1>
              <p style="margin:0 0 24px 0;text-align:center;font-size:16px;line-height:1.4;color:#84848c;"><%= subheading %></p>

              <p style="margin:0 0 16px 0;text-align:left;font-size:16px;line-height:1.5;color:#282538;"><%= hello %></p>
              <p style="margin:0 0 24px 0;text-align:left;font-size:16px;line-height:1.5;color:#282538;"><%= intro %></p>

              <!-- CTA button -->
              <table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center" style="margin:0 auto 24px auto;">
                <tr><td bgcolor="#433cc5" align="center" style="border-radius:8px;">
                  <a href="<%= verify_url %>" style="display:inline-block;padding:14px 32px;font-weight:600;font-size:16px;color:#ffffff;text-decoration:none;border-radius:8px;"><%= button_label %></a>
                </td></tr>
              </table>

              <p style="margin:0 0 6px 0;text-align:center;font-size:14px;line-height:1.4;color:#84848c;"><%= fallback_label %></p>
              <p style="margin:0 0 24px 0;text-align:center;font-size:14px;line-height:1.4;word-break:break-all;color:#433cc5;"><%= verify_url %></p>

              <!-- Security note -->
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:#f2f2f7;border-radius:8px;">
                <tr><td style="padding:16px;text-align:left;font-size:13px;line-height:1.5;color:#84848c;">
                  <strong style="color:#282538;"><%= security_title %></strong><br><%= security_note %>
                </td></tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td bgcolor="#f2f2f7" align="center" style="background:#f2f2f7;border-top:1px solid #d1d1d6;padding:24px 32px;text-align:center;">
              <p style="margin:0;text-align:center;font-size:10px;line-height:1.4;color:#84848c;">&copy; <%= new Date().getFullYear() %> Drumee. All rights reserved.
                &nbsp;|&nbsp;<a href="https://drumee.com/privacy/" style="color:#84848c;text-decoration:none;">Privacy Policy</a>
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
```

- [ ] **Step 2: Verify the template renders with sample data**

Run (smoke-renders the template the same way the service will):
```bash
cd /home/drumee/loby && node -e "
const { template } = require('lodash');
const fs = require('fs');
const tpl = fs.readFileSync('service/templates/verify-email.html','utf8');
const html = template(tpl)({
  heading:'Verify Your Email Address', subheading:'Thank you for registering with Drumee',
  hello:'Hello Alex,', intro:'Welcome to Drumee! Please verify your email address by clicking the button below.',
  button_label:'Verify Email Address', verify_url:'https://drumee.io/-/#/welcome/verify?token=abc123',
  fallback_label:'Or copy and paste this link into your browser:',
  security_title:'Security Note', security_note:'This verification link will expire in 24 hours.'
});
console.log(html.length > 0 && html.includes('abc123') ? 'OK render' : 'FAIL');"
```
Expected: prints `OK render`.

- [ ] **Step 3: Commit**

```bash
cd /home/drumee/loby
git add service/templates/verify-email.html
git commit -m "feat(loby): add verify-email link email template"
```

---

## Task 4: loby — send the verify link on account creation

**Files:**
- Modify: `/home/drumee/loby/service/signup.js`

Add a private helper that mints the token (via the YP proc) and emails the link, then call it from `create_account` after the account exists. Leave the OTP code in `save_info` untouched (dead, per scope). `this.yp.await_proc` runs YP procs; `this.input.homepath()` gives the app base; verify link mirrors the existing `#/welcome/...` routing.

- [ ] **Step 1: Add the `_send_verification_email` helper**

Insert this method into the `Signup` class (e.g. just after `send_signup_welcome`, near line 90). `_uid` is the drumate id, `_email` the address:

```js
  /**
   * Mint a verification token and email the verify link.
   */
  async _send_verification_email(_uid, _email) {
    const { token } = await this.yp.await_proc("drumate_set_verification_token", _uid, _email) || {};
    if (!token) {
      this.warn("[_send_verification_email] no token minted for", _email);
      return 0;
    }
    const homepath = this.input.homepath();
    const verify_url = `${homepath}#/welcome/verify?token=${encodeURIComponent(token)}`;
    const ulang = this.input.ua_language();
    const lex = Cache.lex(ulang);
    const data = {
      heading: lex._verify_your_email || "Verify Your Email Address",
      subheading: lex._thanks_for_registering || "Thank you for registering with Drumee",
      hello: (lex._hello_x || "Hello %s,").format(_email),
      intro: lex._verify_email_intro ||
        "Welcome to Drumee! To complete your registration, please verify your email address by clicking the button below.",
      button_label: lex._verify_email_button || "Verify Email Address",
      verify_url,
      fallback_label: lex._verify_email_fallback || "Or copy and paste this link into your browser:",
      security_title: lex._security_note_title || "Security Note",
      security_note: lex._verify_email_expiry ||
        "This verification link will expire in 24 hours. For your security, please do not share this email with anyone.",
    };
    const msg = new Messenger({
      subject: lex._verify_your_email || "Verify Your Email Address",
      recipient: _email,
      handler: this.exception.email,
    });
    try {
      const tpl = resolve(__dirname, "./templates/verify-email.html");
      const html = msg.renderFrom(tpl, data);
      await msg.send({ html });
      return 1;
    } catch (e) {
      this.warn("[_send_verification_email] send failed", e);
      return 0;
    }
  }
```

- [ ] **Step 2: Call the helper from `create_account`**

In `create_account`, replace the existing welcome-email line (`await this.send_signup_welcome(email)`, ~line 156) with the verification send. The account is created above as `registration_verified=0` (DB default); `res.user.id` is the drumate id:

```js
    await this._send_verification_email(res.user.id, email);
```

(The welcome email moves to after verification in a later iteration; for now the verify email is the post-signup email. If `res.user.id` is undefined here, fall back to `this.uid`, which is set just above.)

- [ ] **Step 3: Smoke-check the module loads**

Run:
```bash
cd /home/drumee/loby && node -e "require('./service/signup.js'); console.log('signup.js loads OK');"
```
Expected: prints `signup.js loads OK` with no syntax error.

- [ ] **Step 4: Commit**

```bash
cd /home/drumee/loby
git add service/signup.js
git commit -m "feat(loby): email verification link on account creation"
```

---

## Task 5: loby — verify_email service + ACL

**Files:**
- Modify: `/home/drumee/loby/service/signup.js`
- Modify: `/home/drumee/loby/acl/signup.json`

- [ ] **Step 1: Add the `verify_email` method**

Add to the `Signup` class. Reads `token` from input, calls the YP proc, returns `{ verified }`:

```js
  /**
   * Verify a signup email from the link token. Public/anonymous.
   */
  async verify_email() {
    const token = this.input.need(Attr.token);
    const res = await this.yp.await_proc("drumate_verify_email_token", token) || {};
    this.output.data({ verified: res.verified === 1 ? 1 : 0 });
  }
```

If `Attr.token` is not defined in the essentials `Attr` map, use the literal `"token"`: `const token = this.input.need("token");`. Confirm with:
```bash
cd /home/drumee/loby && node -e "console.log(require('@drumee/server-essentials').Attr.token)"
```
If it prints `undefined`, use the string literal form.

- [ ] **Step 2: Register the ACL entry**

In `acl/signup.json`, add a `verify_email` entry alongside the others (same anonymous/public-api shape):

```json
    "verify_email": {
      "scope": "hub",
      "permission": {
        "src": "anonymous",
        "fast_check": "public-api"
      }
    },
```

- [ ] **Step 3: Verify ACL is valid JSON and module loads**

Run:
```bash
cd /home/drumee/loby && node -e "JSON.parse(require('fs').readFileSync('acl/signup.json','utf8')); require('./service/signup.js'); console.log('OK');"
```
Expected: prints `OK`.

- [ ] **Step 4: Commit**

```bash
cd /home/drumee/loby
git add service/signup.js acl/signup.json
git commit -m "feat(loby): add verify_email service endpoint"
```

---

## Task 6: loby — resend_verification service + ACL

**Files:**
- Modify: `/home/drumee/loby/service/signup.js`
- Modify: `/home/drumee/loby/acl/signup.json`

Backs S1's "Resend email". Uses the session's stored signup email (`signup_data` keyed by `session_id`), looks up the drumate, re-mints + re-sends.

- [ ] **Step 1: Add the `resend_verification` method**

```js
  /**
   * Re-mint the verification token and re-send the link. Public/anonymous.
   */
  async resend_verification() {
    const sessionId = this.input.sid();
    const sql = `SELECT email FROM ${this.app_db}.signup_data WHERE session_id=?`;
    const { email } = await this.db.await_query(sql, sessionId) || {};
    if (!email) {
      return this.output.data({ status: "no_pending_signup" });
    }
    const user = await this.yp.await_proc("drumate_exists", email);
    if (!user || !user.id) {
      return this.output.data({ status: "no_account", email });
    }
    const sent = await this._send_verification_email(user.id, email);
    this.output.data({ status: "ok", sent, email });
  }
```

(`drumate_exists` returns the drumate row including `id`; confirm the id field name with the existing `create_account`/`drumate_exists` usage in `service/lib/loby.js` — adjust `user.id` if the proc returns a different key.)

- [ ] **Step 2: Register the ACL entry**

In `acl/signup.json`, add:

```json
    "resend_verification": {
      "scope": "hub",
      "permission": {
        "src": "anonymous",
        "fast_check": "public-api"
      }
    },
```

- [ ] **Step 3: Verify ACL valid + module loads**

Run:
```bash
cd /home/drumee/loby && node -e "JSON.parse(require('fs').readFileSync('acl/signup.json','utf8')); require('./service/signup.js'); console.log('OK');"
```
Expected: prints `OK`.

- [ ] **Step 4: Commit**

```bash
cd /home/drumee/loby
git add service/signup.js acl/signup.json
git commit -m "feat(loby): add resend_verification service endpoint"
```

---

## Task 7: Frontend — locale strings

**Files:**
- Modify: `/home/drumee/signup/src/locale/en.json`

- [ ] **Step 1: Add the link-flow strings**

Add these keys (keep the existing code-entry keys untouched per scope). `{0}` is the lodash-style positional used elsewhere in this file (e.g. `ENTER_VERIFICATION_CODE`):

```json
  "CHECK_YOUR_INBOX": "Check your inbox",
  "WE_SENT_LINK_TO": "We sent a verification link to",
  "RESEND_EMAIL": "Resend email",
  "CANCEL": "Cancel",
  "EMAIL_CONFIRMED": "Email confirmed",
  "EMAIL_VERIFIED_BODY": "Your email has been verified. You can now access all Drumee features.",
  "BACK_TO_DRUMEE": "Back to Drumee",
  "VERIFY_FAILED": "This link is invalid or has expired.",
  "VERIFYING": "Verifying…"
```

- [ ] **Step 2: Verify valid JSON**

Run:
```bash
cd /home/drumee/signup && node -e "JSON.parse(require('fs').readFileSync('src/locale/en.json','utf8')); console.log('locale OK');"
```
Expected: prints `locale OK`.

- [ ] **Step 3: Commit**

```bash
cd /home/drumee/signup
git add src/locale/en.json
git commit -m "feat(signup): add email-verification locale strings"
```

---

## Task 8: Frontend — S1 "Check your inbox" widget

**Files:**
- Create: `/home/drumee/signup/src/widgets/check-inbox/index.js`
- Create: `/home/drumee/signup/src/widgets/check-inbox/skeleton/index.js`
- Create: `/home/drumee/signup/src/widgets/check-inbox/skin/index.scss`
- Modify: `/home/drumee/signup/src/seeds.js`
- Modify: `/home/drumee/signup/src/widgets/router/index.js`
- Modify: `/home/drumee/signup/src/widgets/form/index.js`

Follows the existing widget pattern: a class extending the common base (`require("..")` → `signup_common`), `onDomRefresh` feeds a skeleton built from `toolkit/skeleton` helpers (`button`, `header`), services dispatched via `postService(SERVICE.signup.*)` and bubbled via `onUiEvent`.

- [ ] **Step 1: Write the S1 skeleton**

`src/widgets/check-inbox/skeleton/index.js`:

```js
const { header, button } = require("../../toolkit/skeleton")

function __skl_check_inbox(ui) {
  const fam = ui.fig.family
  const email = ui.mget(_a.email) || ""
  return Skeletons.Box.Y({
    className: `${fam}__check-inbox`,
    kids: [
      header(ui, LOCALE.CHECK_YOUR_INBOX),
      Skeletons.Element({
        className: `${fam}__text`,
        content: `${LOCALE.WE_SENT_LINK_TO}`,
      }),
      Skeletons.Element({
        className: `${fam}__email`,
        content: email,
      }),
      button(ui, {
        label: LOCALE.RESEND_EMAIL,
        service: 'resend-email',
        ico: 'refresh',
        type: _a.row,
        sys_pn: 'resend-button',
        priority: 'primary',
      }),
      button(ui, {
        label: LOCALE.CANCEL,
        service: 'cancel-verify',
        sys_pn: 'cancel-button',
        priority: 'secondary',
      }),
    ]
  })
}

module.exports = { default: __skl_check_inbox }
```

- [ ] **Step 2: Write the S1 widget class**

`src/widgets/check-inbox/index.js`:

```js
const Signup = require("..")
require('./skin');

class signup_check_inbox extends Signup {

  initialize(opt = {}) {
    super.initialize(opt);
    this.mset({ email: opt.email || this.mget(_a.email) || "" });
    this.declareHandlers();
  }

  onDomRefresh() {
    this.feed(require('./skeleton').default(this));
  }

  onUiEvent(cmd, args = {}) {
    const service = args.service || cmd.mget(_a.service);
    switch (service) {
      case 'resend-email':
        this.setItemStatus('resend-button', 'pending');
        this.postService(SERVICE.signup.resend_verification, {}).then(() => {
          this.setItemStatus('resend-button', 'sent');
        }).catch(() => {
          this.setItemStatus('resend-button', '');
        });
        break;
      case 'cancel-verify':
        location.hash = "#/welcome/signup";
        break;
      default:
        this.debug("check-inbox: unknown service", service);
    }
  }
}

module.exports = signup_check_inbox
```

- [ ] **Step 3: Write the S1 skin (centered card; mirror form skin)**

`src/widgets/check-inbox/skin/index.scss`:

```scss
.signup__check-inbox {
  align-items: center;
  text-align: center;
  gap: 12px;

  .signup__email { font-weight: 700; }
  .signup__text { color: #282538; }
}
```

- [ ] **Step 4: Register the widget in seeds.js**

In `src/seeds.js`, add the line inside the exported object:

```js
	'signup_check_inbox': import('./widgets/check-inbox'),
```

- [ ] **Step 5: Route to S1 after successful signup**

In `src/widgets/form/index.js`, `createAccount()` success branch currently does `location.reload()`. Replace that with bubbling to the router to show S1 (keep the email):

```js
    this.postService(SERVICE.signup.create_account, { email, password }).then((data) => {
      if (data.status == _a.ok) {
        this.triggerHandlers({ service: 'verification-sent', email });
        return
      }
```

- [ ] **Step 6: Handle the transition in the router**

In `src/widgets/router/index.js` `onUiEvent` switch, add a case that feeds the S1 widget with the email:

```js
      case 'verification-sent':
        this.feed({ kind: 'signup_check_inbox', email: args.email });
        break;
```

- [ ] **Step 7: Build and verify it compiles**

Run:
```bash
cd /home/drumee/signup && npx webpack --config webpack.js 2>&1 | tail -20
```
Expected: build completes with no module-resolution or syntax errors for the new `check-inbox` files. (If the project uses `npm run dev` only, run that and confirm it boots without compile errors, then stop it.)

- [ ] **Step 8: Commit**

```bash
cd /home/drumee/signup
git add src/widgets/check-inbox src/seeds.js src/widgets/router/index.js src/widgets/form/index.js
git commit -m "feat(signup): add 'Check your inbox' screen after signup"
```

---

## Task 9: Frontend — S2 "Email confirmed" verify route

**Files:**
- Create: `/home/drumee/signup/src/widgets/verified/index.js`
- Create: `/home/drumee/signup/src/widgets/verified/skeleton/index.js`
- Create: `/home/drumee/signup/src/widgets/verified/skin/index.scss`
- Modify: `/home/drumee/signup/src/seeds.js`
- Modify: `/home/drumee/signup/src/widgets/router/index.js`

S2 is shown at `#/welcome/verify?token=…`. On mount it reads `token` from the module args (`Visitor.parseModuleArgs()`, the same call the router already uses for `email`), calls `verify_email`, and renders the confirmed or error state.

- [ ] **Step 1: Write the S2 skeleton**

`src/widgets/verified/skeleton/index.js`:

```js
const { header, button } = require("../../toolkit/skeleton")

function __skl_verified(ui) {
  const fam = ui.fig.family
  const ok = ui.mget('verified')
  return Skeletons.Box.Y({
    className: `${fam}__verified`,
    kids: [
      header(ui, ok ? LOCALE.EMAIL_CONFIRMED : LOCALE.VERIFY_FAILED),
      Skeletons.Element({
        className: `${fam}__text`,
        content: ok ? LOCALE.EMAIL_VERIFIED_BODY : LOCALE.VERIFY_FAILED,
      }),
      button(ui, {
        label: ok ? LOCALE.BACK_TO_DRUMEE : LOCALE.RESEND_EMAIL,
        service: ok ? 'back-to-drumee' : 'resend-email',
        sys_pn: 'verified-button',
        priority: 'primary',
      }),
    ]
  })
}

module.exports = { default: __skl_verified }
```

- [ ] **Step 2: Write the S2 widget class (verify-on-load)**

`src/widgets/verified/index.js`:

```js
const Signup = require("..")
require('./skin');

class signup_verified extends Signup {

  initialize(opt = {}) {
    super.initialize(opt);
    this.declareHandlers();
    const args = Visitor.parseModuleArgs() || {};
    this._token = opt.token || args.token || "";
    this.mset({ verified: 0 });
  }

  onDomRefresh() {
    this.feed(require('./skeleton').default(this));
    if (!this._token) {
      this.mset({ verified: 0 });
      this.refresh();
      return;
    }
    this.postService(SERVICE.signup.verify_email, { token: this._token }).then((data) => {
      this.mset({ verified: data && data.verified ? 1 : 0 });
      this.refresh();
    }).catch(() => {
      this.mset({ verified: 0 });
      this.refresh();
    });
  }

  onUiEvent(cmd, args = {}) {
    const service = args.service || cmd.mget(_a.service);
    switch (service) {
      case 'back-to-drumee':
        location.href = "/-/";
        break;
      case 'resend-email':
        this.postService(SERVICE.signup.resend_verification, {}).catch(() => {});
        break;
      default:
        this.debug("verified: unknown service", service);
    }
  }
}

module.exports = signup_verified
```

(Confirm the re-render call name during implementation: the codebase uses `this.feed(...)` to (re)render a skeleton — if `this.refresh()` is not a method on `LetcBox`, replace the two `this.refresh()` calls with `this.feed(require('./skeleton').default(this))`.)

- [ ] **Step 3: Write the S2 skin**

`src/widgets/verified/skin/index.scss`:

```scss
.signup__verified {
  align-items: center;
  text-align: center;
  gap: 12px;

  .signup__text { color: #282538; }
}
```

- [ ] **Step 4: Register the widget in seeds.js**

In `src/seeds.js`, add:

```js
	'signup_verified': import('./widgets/verified'),
```

- [ ] **Step 5: Route `#/welcome/verify` to S2**

In `src/widgets/router/index.js` `onDomRefresh`, the router currently always feeds `signup_form`. Branch on the presence of a `token` arg so the verify route renders S2 instead:

```js
  onDomRefresh() {
    Kind.waitFor('dtk_pwsetter').then(() => {
      const args = Visitor.parseModuleArgs() || {};
      if (args.token) {
        this.feed({ kind: 'signup_verified', token: args.token });
        return;
      }
      let email = '';
      if (args.email) {
        try { email = decodeURIComponent(args.email); } catch (e) { email = args.email; }
      }
      this.feed({ kind: 'signup_form', email });
    })
  }
```

(The `dtk_pwsetter` wait is harmless for the verify path; keeping it avoids reworking the router's readiness flow. If the verify screen must not depend on the password widget loading, move the `args.token` check above `Kind.waitFor` during implementation.)

- [ ] **Step 6: Build and verify it compiles**

Run:
```bash
cd /home/drumee/signup && npx webpack --config webpack.js 2>&1 | tail -20
```
Expected: build completes with no errors for the new `verified` files.

- [ ] **Step 7: Commit**

```bash
cd /home/drumee/signup
git add src/widgets/verified src/seeds.js src/widgets/router/index.js
git commit -m "feat(signup): add 'Email confirmed' verify-link screen"
```

---

## Task 10: End-to-end manual verification

**Files:** none (manual)

- [ ] **Step 1: Patch the new procs to all live instances**

Per `CLAUDE.md`, YP procs apply to the single YP DB; confirm both new procs exist:
```bash
mysql -S /var/run/mysqld/mysqld.sock yp -e "SHOW PROCEDURE STATUS WHERE Db='yp' AND Name IN ('drumate_set_verification_token','drumate_verify_email_token');"
```
Expected: two rows.

- [ ] **Step 2: Run the apps (loby + signup) per their dev scripts**

```bash
cd /home/drumee/loby && npm run dev   # backend
# in a second shell:
cd /home/drumee/signup && npm run dev  # frontend
```

- [ ] **Step 3: Walk the flow**

1. Open the signup page (`#/welcome/signup`), submit a new email + password.
2. Confirm S1 "Check your inbox" appears with the email shown.
3. Confirm an email arrives (or check the loby mail log / MTA) with a `#/welcome/verify?token=…` link.
4. Open the link → confirm S2 "Email confirmed" appears.
5. Check the DB: `SELECT registration_verified, email, unverified_email FROM drumate WHERE email='<that email>';` → `registration_verified=1`, `unverified_email` NULL.
6. Click "Resend email" on S1 (before verifying a fresh signup) → confirm a new link arrives and the old token no longer verifies (`drumate_verify_email_token('<old>')` → 0).

- [ ] **Step 4: Confirm and report**

Report pass/fail of each sub-step with the actual DB output. No commit (verification only).

---

## Notes / Out of Scope (follow-up)

- The dead OTP path (`save_signup_info` 6-digit otp, `signup_data.otp` column, `verify_otp` ACL entry, OTP `onboarding.js` template) is intentionally left in place. Track a cleanup follow-up.
- "Back to Drumee" routes to `/-/`. If signup auto-login (`session.signin` in `create_account`) does not persist across the verify-link navigation (link opened in a different browser/tab), the user may land logged-out at `/-/`; that is acceptable for v1 and matches "access all Drumee features" after a normal login.
- Rate-limiting of resend relies on existing infra; no new throttle added.
