-- File: schemas/yellow_page/tables/department_grant.sql
-- Purpose: the workspace access a DEPARTMENT gave a person (title Default
--          access, B2B Org Structure) — the sidecar that lets that access be
--          taken back without touching what was granted by hand.
--
-- WHY A SIDECAR. The grant itself is an ordinary permission row in the hub's
-- own database (written by member_save_workspace_roles), so every existing
-- access check keeps working unchanged. That row has no column that could
-- say "a department put me here" (permission is written positionally by many
-- procedures), so this table says it instead.
--
-- prev_privilege is what the person had in the workspace BEFORE the
-- department raised it (0 = not a member). Taking the grant back restores it:
-- removes the membership when it was 0, sets it back otherwise.
CREATE TABLE IF NOT EXISTS `department_grant` (
  `domain_id` int(11) unsigned NOT NULL,
  `hub_id` varchar(16) NOT NULL COMMENT 'the workspace',
  `uid` varchar(16) NOT NULL COMMENT 'the person',
  `privilege` tinyint(4) unsigned NOT NULL COMMENT 'what the department granted',
  `prev_privilege` tinyint(4) unsigned NOT NULL DEFAULT 0 COMMENT 'what they had before, 0 = none',
  `mtime` int(11) unsigned NOT NULL,
  PRIMARY KEY (`hub_id`,`uid`),
  KEY `idx_domain` (`domain_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Workspace access granted by department membership (title rules)';
