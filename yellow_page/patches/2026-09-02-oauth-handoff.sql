-- =========================================================
-- Add yp.oauth_handoff — the one-time hand-off of a verified OAuth
-- identity to a mobile app session.
--
-- The web OAuth callback signs in the session that called initiate
-- (oauth_state.session_id). Inside a browser that is the same session
-- that completes the redirect, so it is safe there. A mobile app cannot
-- work that way: the redirect ends in a system auth sheet that holds no
-- app session, and binding the login to "whoever called initiate" would
-- let a phished authUrl sign a victim into an attacker's session.
--
-- So for mobile the callback only VERIFIES and PARKS: the provider
-- profile goes into this table behind a random code, the sheet is sent
-- back to the app with that code, and the app redeems it with
-- oauth.claim over its own header session — which has to be the very
-- session that started the flow. Neither half is enough alone.
--
-- ONE TABLE, not more columns on oauth_state: a hand-off is a different
-- object with a different lifetime (seconds, redeemed by the app) from
-- a CSRF state (minutes, consumed by the provider callback), and mixing
-- the two would let one be spent as the other.
--
-- CREATE TABLE IF NOT EXISTS, so this is safe to replay. Rows are swept
-- by every writer (ctime older than 120 s), idx_ctime serves that.
-- =========================================================

CREATE TABLE IF NOT EXISTS `oauth_handoff` (
  `code` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL
    COMMENT '32 hex, CSPRNG; single use',
  `session_id` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL
    COMMENT 'The session that called initiate; the only one allowed to claim',
  `provider` varchar(20) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `profile` json NOT NULL
    COMMENT 'Verified provider profile (email, provider_id, names, tokens, ref, utm)',
  `ctime` int unsigned NOT NULL COMMENT 'Unix timestamp (created_at)',
  PRIMARY KEY (`code`),
  KEY `idx_ctime` (`ctime`)
) ENGINE=InnoDB DEFAULT CHARSET=ascii COLLATE=ascii_general_ci
COMMENT='One-time hand-off of a verified OAuth identity to a mobile session';
