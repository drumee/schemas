-- File: schemas/yellow_page/tables/002_create_mfs_token.sql
-- Purpose: Create mfs_pre_authorized table to store MFS node that
--          The tokenis used to retrieve the node that has been stored during previous authirzation
DROP TABLE IF EXISTS mfs_authorized_node;
CREATE TABLE IF NOT EXISTS mfs_authorized_node (
  sys_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sessionKey VARCHAR(64) CHARACTER SET ascii,
  hub_id VARCHAR(16) 
    COMMENT 'Reference to hub database',

  nid VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL
    COMMENT 'Reference to media.id in hub database',

  uid VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL
    COMMENT 'Reference to yp.entity.id (sessionKey creator)',

  expiry INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Unix timestamp (expiry), 0 = no expiry',
  ctime INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Unix timestamp (created_at)',
  INDEX idx_hub_node (hub_id, nid),
  INDEX idx_uid (uid),
  INDEX idx_expiry (expiry),
  UNIQUE KEY `idx_sessionKey` (`sessionKey`)
)
COMMENT='MFS export/import tokens for cross-Drumee data transfer';