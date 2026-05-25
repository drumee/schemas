-- quota_usage: Cache domain usage for paid plans
-- Links to quota table via domain_id

USE yp;

DROP TABLE IF EXISTS `quota_usage`;

CREATE TABLE IF NOT EXISTS `quota_usage` (
  `domain_id` int(11) unsigned NOT NULL,
  `cached_usage` bigint unsigned DEFAULT 0,
  `actual_usage` bigint unsigned DEFAULT 0,
  `drift` bigint DEFAULT 0,
  `ctime` int(11) unsigned DEFAULT 0,
  `mtime` int(11) unsigned DEFAULT 0,
  `last_recalc` int(11) unsigned DEFAULT 0,
  PRIMARY KEY (`domain_id`),
  CONSTRAINT `fk_quota_usage_domain` 
    FOREIGN KEY (`domain_id`) 
    REFERENCES `quota` (`domain_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  KEY `idx_mtime` (`mtime`),
  KEY `idx_last_recalc` (`last_recalc`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Initialize for existing paid domains
INSERT INTO quota_usage (domain_id, cached_usage, ctime, mtime)
SELECT domain_id, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()
FROM quota 
WHERE domain_id > 1;

SELECT 'quota_usage table created' AS status;