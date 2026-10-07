-- File: schemas/yellow_page/tables/org_title.sql
-- Purpose: the titles an ORGANISATION adds on top of the three built-in ones
--          (director / manager / executive) — the "+ New Title" row of the
--          Admin Console Title dropdown and the Org Structure "New level
--          subordinate" (B2B Org Structure, Figma 900:149745).
--
-- THE BUILT-INS ARE NOT ROWS HERE. They stay the fixed keys member_title_set
-- has always accepted, so an organisation that never adds a title needs no
-- seeding and nothing about the existing three changes. A custom title's
-- NAME is what member_title.title stores for it, exactly as a built-in's key
-- is: the Member tab and the chart keep reading one column.
--
-- NAMES ARE UNIQUE WITHIN AN ORGANISATION, case-insensitively (the table's
-- utf8mb4_general_ci), and may not reuse a built-in key — org_title_add
-- refuses both with TITLE_EXISTS.
--
-- NO FOREIGN KEYS, matching yp's style (department, member_title).

CREATE TABLE IF NOT EXISTS `org_title` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) NOT NULL
    COMMENT 'Opaque public id, minted from UUID()',
  `domain_id` int(11) unsigned NOT NULL
    COMMENT 'Reference to yp.domain.id — the organisation that added it',
  `name` varchar(64) NOT NULL
    COMMENT 'Display name, typed by an org admin; also the value member_title stores',
  `rank` int(11) unsigned NOT NULL DEFAULT 0
    COMMENT 'Order after the built-ins; ties break on ctime',
  `by_id` varchar(16) DEFAULT NULL
    COMMENT 'Reference to yp.drumate.id — who added it. Informational only.',
  `ctime` int(11) unsigned NOT NULL COMMENT 'Unix timestamp, created',
  `mtime` int(11) unsigned NOT NULL COMMENT 'Unix timestamp, last renamed',
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `domain_name` (`domain_id`,`name`),
  KEY `idx_domain` (`domain_id`,`rank`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Custom member titles per organisation — Admin Console Title column';
