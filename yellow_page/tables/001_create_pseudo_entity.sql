-- File: schemas/yellow_page/tables/001_create_pseudo_entity.sql
-- Purpose: Create pseudo_entity table to store pseudo entities that can be used for various purposes
--          including OAuth export tokens, API access, and future extensions

USE yp;

CREATE TABLE IF NOT EXISTS yp.pseudo_entity (
  sys_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  
  pseudo_entity VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  
  uid VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL
    COMMENT 'Reference to yp.entity.id (creator)',
  
  token VARCHAR(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  
  ctime INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Unix timestamp (created_at)',
  
  UNIQUE KEY uni_pseudo_token (pseudo_entity, token),
  
  INDEX idx_token (token),
  
  INDEX idx_uid (uid),
  
  CONSTRAINT fk_pseudo_entity_creator
    FOREIGN KEY (uid)
    REFERENCES yp.entity(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
COMMENT='Pseudo entities for API access control and token-based authorization';