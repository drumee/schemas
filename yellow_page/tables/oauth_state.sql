-- File: ~/schemas/yellow_page/tables/002_create_oauth_state_table.sql
-- Purpose: Store OAuth state parameters for CSRF protection
DROP TABLE IF EXISTS oauth_state;
CREATE TABLE IF NOT EXISTS oauth_state (
  state VARCHAR(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL PRIMARY KEY,
  session_id VARCHAR(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  ctime INT UNSIGNED NOT NULL COMMENT 'Unix timestamp (created_at)',
  
  INDEX idx_ctime (ctime)
) ENGINE=InnoDB DEFAULT CHARSET=ascii COLLATE=ascii_general_ci
COMMENT='Temporary storage for OAuth state parameters (CSRF protection)';