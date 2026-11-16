-- =========================================================
-- analytics_tracked_user
-- Named, fixed lists of accounts the analytics dashboard can restrict a
-- page to. The five Activation / Engagement procs read `_args.tracked`
-- (a list_name) and, when given, count only the accounts on that list;
-- analytics_tracked_ok() is the one rule. Without `tracked` nothing changes.
--
-- First list: 'other-top100' -- the 100 users with the most Activation and
-- Engagement data on 2026-11-16, tracked by the dashboard's Other page.
-- =========================================================
CREATE TABLE IF NOT EXISTS `analytics_tracked_user` (
  `list_name` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL
    COMMENT 'Which list -- what the dashboard sends as `tracked`',
  `uid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL
    COMMENT 'Reference to yp.drumate.id',
  `ctime` int(11) unsigned NOT NULL COMMENT 'When the account was put on the list',
  PRIMARY KEY (`list_name`, `uid`),
  KEY `idx_uid` (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Analytics: named lists of tracked accounts';
