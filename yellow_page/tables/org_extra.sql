-- =========================================================
-- org_extra -- organisations created with "+ New organization" (multi-org).
-- =========================================================
-- organisation.owner_id is UNIQUE and already holds the creator's first
-- organisation, so an extra one is created with owner_id NULL and its owner
-- recorded here (and as a 63 row in org_membership). prev_entity keeps the
-- pool entity's columns as they were, so org_extra_delete can hand it back
-- exactly.
CREATE TABLE IF NOT EXISTS `org_extra` (
  `domain_id`   int(11) unsigned NOT NULL,
  `org_id`      varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `owner_uid`   varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `prev_entity` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`prev_entity`)),
  `ctime`       int(11) unsigned NOT NULL,
  PRIMARY KEY (`domain_id`),
  UNIQUE KEY `org_id` (`org_id`),
  KEY `idx_owner` (`owner_uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
  COMMENT='Extra organisations (multi-org), for ownership and rollback';
