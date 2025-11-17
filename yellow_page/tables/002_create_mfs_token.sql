-- File: schemas/yellow_page/tables/002_create_mfs_token.sql
-- Purpose: Create mfs_token table to store MFS export/import tokens
--          One token can access multiple resources (hub_id + node_id combinations)

USE yp;

CREATE TABLE IF NOT EXISTS yp.mfs_token (
  sys_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  
  token VARCHAR(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL UNIQUE,
  
  hub_id VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL
    COMMENT 'Reference to hub database',
  
  node_id VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL
    COMMENT 'Reference to media.id in hub database',
  
  user_id VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL
    COMMENT 'Reference to yp.entity.id (token creator)',
  
  pseudo_entity_uid VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL
    COMMENT 'Reference to pseudo_entity.pseudo_entity',
  
  expiry_time INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Unix timestamp (expiry), 0 = no expiry',
  
  ctime INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Unix timestamp (created_at)',
  
  INDEX idx_token (token),
  
  INDEX idx_hub_node (hub_id, node_id),
  
  INDEX idx_user_id (user_id),
  
  INDEX idx_pseudo_entity_uid (pseudo_entity_uid),
  
  INDEX idx_expiry_time (expiry_time),
  
  CONSTRAINT fk_mfs_token_creator
    FOREIGN KEY (user_id)
    REFERENCES yp.entity(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE

) ENGINE=InnoDB DEFAULT CHARSET=ascii COLLATE=ascii_general_ci
COMMENT='MFS export/import tokens for cross-Drumee data transfer';