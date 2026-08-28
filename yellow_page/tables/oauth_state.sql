-- File: ~/schemas/yellow_page/tables/002_create_oauth_state_table.sql
-- Purpose: Store OAuth state parameters for CSRF protection
DROP TABLE IF EXISTS oauth_state;
CREATE TABLE IF NOT EXISTS oauth_state (
  state VARCHAR(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL PRIMARY KEY,
  session_id VARCHAR(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  -- Referral handle (?ref=) captured by loby's google.initiate / apple.initiate
  -- and read back by handleOAuthCallback. It has to live here because the
  -- callback is server-side and the visitor is bounced out to the provider in
  -- between, so browser storage is unreachable. See
  -- patches/2026-08-11-oauth-state-ref.sql.
  ref VARCHAR(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  -- The campaign the visitor arrived on, parked here for the same reason and
  -- by the same code as `ref` above: the callback is server-side and browser
  -- storage is unreachable across the bounce to the provider. Without these an
  -- OAuth signup on a campaign link is recorded as organic. See
  -- patches/2026-08-24-oauth-state-utm.sql.
  utm_source VARCHAR(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  utm_medium VARCHAR(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  utm_campaign VARCHAR(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  utm_content VARCHAR(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  ctime INT UNSIGNED NOT NULL COMMENT 'Unix timestamp (created_at)',
  
  INDEX idx_ctime (ctime)
) ENGINE=InnoDB DEFAULT CHARSET=ascii COLLATE=ascii_general_ci
COMMENT='Temporary storage for OAuth state parameters (CSRF protection)';