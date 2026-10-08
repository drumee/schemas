-- File: schemas/yellow_page/tables/org_join_link.sql
-- Purpose: the "Public link" of the setup wizard's invite step (Figma
--          998:85923): one shareable link that puts whoever opens it into the
--          workspaces of the chosen departments, until it expires or is
--          revoked. Multi-use, unlike the per-email hub invite tokens.
CREATE TABLE IF NOT EXISTS `org_join_link` (
  `id` varchar(32) NOT NULL COMMENT 'the token in the URL',
  `domain_id` int(11) unsigned NOT NULL,
  `departments` longtext NOT NULL COMMENT 'JSON array of department ids',
  `privilege` tinyint(4) unsigned NOT NULL DEFAULT 3 COMMENT 'access granted when no title rule applies',
  `expires_at` int(11) unsigned NOT NULL DEFAULT 0 COMMENT '0 = never',
  `revoked` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `uses` int(11) unsigned NOT NULL DEFAULT 0,
  `by_id` varchar(16) DEFAULT NULL,
  `ctime` int(11) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_domain` (`domain_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Department join links (setup wizard Public link)';
