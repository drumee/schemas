-- =========================================================
-- Add oauth_state.ref — the referral handle for an OAuth signup.
--
-- The signup UI captures ?ref=<member> in browser storage. The OAuth
-- callback runs server-side and cannot read that, and the visitor is
-- bounced out to Google/Apple in between, so the handle has to be
-- parked somewhere that survives the round trip. loby's
-- google.initiate / apple.initiate park it on the state row they
-- already create for CSRF protection, and handleOAuthCallback reads
-- it back out (SELECT s.*) to thread it into create_account's profile,
-- where the analytics referral procs look for it.
--
-- Both initiate methods already write it:
--
--   INSERT IGNORE INTO oauth_state (state, session_id, ref, ctime)
--     VALUES (?, ?, ?, UNIX_TIMESTAMP())
--
-- wrapped in a try/catch that falls back to a 3-column insert "on a
-- DB without the optional oauth_state.ref column". No schema here has
-- ever had that column -- not tables/oauth_state.sql, not
-- templates/factory/seed/yp.sql -- so on a freshly seeded database
-- the fallback is not a fallback, it is the only path: every OAuth
-- signup loses its referral attribution, and because the catch is
-- silent nothing says so.
--
-- Sized to match what initiate stores: it lowercases and truncates to
-- 64 chars before the insert.
--
-- NULLable with no default. A row written without a ref means "this
-- signup had no referrer", which is the common case, and is what the
-- callback's `if (ref)` guard already expects to see.
-- =========================================================

ALTER TABLE `oauth_state`
  ADD COLUMN IF NOT EXISTS `ref` varchar(64)
  CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL
  COMMENT 'Referral handle (?ref=) captured at initiate, read back at callback'
  AFTER `session_id`;
