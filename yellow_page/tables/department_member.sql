-- File: schemas/yellow_page/tables/department_member.sql
-- Purpose: who BELONGS to a department — the Department column of the Admin
--          Console Member tab and the people of the Org Structure chart
--          (B2B Org Structure, Figma 900:149745).
--
-- EXPLICIT, unlike the department chips the console drew before (derived from
-- the workspaces a person happens to be in). Membership is what the title's
-- Default access is applied FROM: a member of a department is granted that
-- access on every workspace of the department (see department_grant).
--
-- A person may belong to several departments of one organisation; a row per
-- (department, person). Keyed by department, scoped by domain for every read.
-- NO FOREIGN KEYS, yp style: a deleted department leaves rows no listing
-- reaches (department_member_list joins department).
CREATE TABLE IF NOT EXISTS `department_member` (
  `domain_id` int(11) unsigned NOT NULL COMMENT 'yp.domain.id — the organisation',
  `department_id` varchar(16) NOT NULL COMMENT 'yp.department.id',
  `uid` varchar(16) NOT NULL COMMENT 'yp.drumate.id',
  `by_id` varchar(16) DEFAULT NULL COMMENT 'who added them. Informational only.',
  `ctime` int(11) unsigned NOT NULL COMMENT 'Unix timestamp, added',
  PRIMARY KEY (`department_id`,`uid`),
  KEY `idx_domain_uid` (`domain_id`,`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='People per department — Admin Console Member tab / Org Structure';
