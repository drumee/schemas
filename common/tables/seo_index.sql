-- SEO Index Table
-- Stores indexed words from documents for full-text search
-- Applies to: Hub and Drumate databases

CREATE TABLE IF NOT EXISTS `seo_index` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nid` VARCHAR(16) CHARACTER SET ascii NOT NULL COMMENT 'Node ID (file id from media table)',
  `hub_id` VARCHAR(16) CHARACTER SET ascii NOT NULL COMMENT 'Owner hub ID',
  `word` VARCHAR(255) NOT NULL COMMENT 'Indexed word (normalized)',
  `position` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Word position in document',
  `frequency` INT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Word frequency in document',
  `created_at` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Timestamp when indexed',
  PRIMARY KEY (`id`),
  KEY `idx_nid` (`nid`),
  KEY `idx_hub_id` (`hub_id`),
  KEY `idx_word` (`word`),
  KEY `idx_nid_hub` (`nid`, `hub_id`),
  FULLTEXT KEY `ft_word` (`word`),
  UNIQUE KEY `key` (`word`, `hub_id`, `nid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='SEO indexed words for full-text search';