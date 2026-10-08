-- =========================================================
-- org_membership -- a person's SECONDARY organisations (B2B multi-org).
-- =========================================================
-- A person's primary organisation stays where it always was: the single
-- privilege row (UNIQUE uid) and drumate.domain_id. This table only ADDS
-- further organisations they belong to, with the same privilege bits
-- (1 member ... 63 owner). Nothing reads it unless the person opens one of
-- those organisations' addresses (service/lib/active-org.js), and
-- domain_permission / domain_privilege fall back to it only when the
-- privilege table has no row for that domain -- an empty table changes
-- nothing anywhere.
CREATE TABLE IF NOT EXISTS `org_membership` (
  `uid`       varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `domain_id` int(11) unsigned NOT NULL,
  `privilege` int(4) unsigned NOT NULL DEFAULT 1,
  `by_id`     varchar(16) DEFAULT NULL,
  `ctime`     int(11) unsigned NOT NULL,
  PRIMARY KEY (`uid`, `domain_id`),
  KEY `idx_domain` (`domain_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
  COMMENT='Secondary organisations of a person (multi-org)';
