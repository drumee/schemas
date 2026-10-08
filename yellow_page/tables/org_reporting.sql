-- File: schemas/yellow_page/tables/org_reporting.sql
-- Purpose: "Reporting To" — the reporting line of the Org Structure chart
--          (Figma 910:132427 Add Subordinate). One row per person who reports
--          to someone; a person with no row reports to the organisation owner.
CREATE TABLE IF NOT EXISTS `org_reporting` (
  `domain_id` int(11) unsigned NOT NULL,
  `uid` varchar(16) NOT NULL COMMENT 'the subordinate',
  `manager_uid` varchar(16) NOT NULL COMMENT 'who they report to',
  `mtime` int(11) unsigned NOT NULL,
  PRIMARY KEY (`domain_id`,`uid`),
  KEY `idx_manager` (`domain_id`,`manager_uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Org chart reporting lines';
