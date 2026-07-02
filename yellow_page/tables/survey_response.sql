CREATE TABLE IF NOT EXISTS `survey_response` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `uid` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'Reference to yp.entity.id',
  `score` tinyint(1) unsigned NOT NULL DEFAULT 0 COMMENT '1-5 star rating',
  `answers` mediumtext DEFAULT NULL COMMENT 'JSON: PMF survey answers (q1..q8, qb1..qb5)',
  `ctime` int(11) unsigned NOT NULL DEFAULT 0,
  `mtime` int(11) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uni_uid` (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='PMF rating survey — one row per user, resubmit updates (upsert)'
