-- A verified OAuth identity parked for a mobile app to redeem.
--
-- The provider callback runs inside a system auth sheet that holds no app
-- session, so it cannot sign the app in; and it must not sign in the session
-- that called initiate, because that binding is what a phished authUrl would
-- exploit. The row therefore carries BOTH the initiator's session id and a
-- one-time code: the code reaches only the device that completed consent, the
-- session id is held only by the app, and oauth.claim needs the two to match.
-- Redeemed within seconds; swept by every writer after 120 s.
CREATE TABLE IF NOT EXISTS oauth_handoff (
  code VARCHAR(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL PRIMARY KEY
    COMMENT '32 hex, CSPRNG; single use',
  session_id VARCHAR(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL
    COMMENT 'The session that called initiate; the only one allowed to claim',
  provider VARCHAR(20) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  profile JSON NOT NULL
    COMMENT 'Verified provider profile (email, provider_id, names, tokens, ref, utm)',
  ctime INT UNSIGNED NOT NULL COMMENT 'Unix timestamp (created_at)',

  INDEX idx_ctime (ctime)
) ENGINE=InnoDB DEFAULT CHARSET=ascii COLLATE=ascii_general_ci
COMMENT='One-time hand-off of a verified OAuth identity to a mobile session';
