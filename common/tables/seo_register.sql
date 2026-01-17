-- SEO Register Table
-- Tracks which files have been indexed and their indexing status
-- Applies to: Hub and Drumate databases

CREATE TABLE IF NOT EXISTS `seo_register` (
  `nid` VARCHAR(16) CHARACTER SET ascii NOT NULL COMMENT 'Node ID (file id from media table)',
  `hub_id` VARCHAR(16) CHARACTER SET ascii NOT NULL COMMENT 'Owner hub ID',
  `category` VARCHAR(16) NOT NULL DEFAULT 'file' COMMENT 'Media category (file, image, etc)',
  `mimetype` VARCHAR(100) DEFAULT NULL COMMENT 'File mimetype',
  `filesize` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'File size in bytes',
  `word_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Total words indexed',
  `indexed_at` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Timestamp when indexed',
  `status` ENUM('pending', 'indexed', 'failed', 'skipped') NOT NULL DEFAULT 'pending' COMMENT 'Indexing status',
  `error_message` TEXT DEFAULT NULL COMMENT 'Error message if indexing failed',
  PRIMARY KEY (`nid`),
  KEY `idx_hub_id` (`hub_id`),
  KEY `idx_status` (`status`),
  KEY `idx_indexed_at` (`indexed_at`),
  KEY `idx_nid_hub` (`nid`, `hub_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='SEO indexing status register';