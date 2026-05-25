DROP TABLE IF EXISTS `share_track`;
CREATE TABLE IF NOT EXISTS `share_track` (
  `sys_id`   int(11) unsigned NOT NULL AUTO_INCREMENT,
  `event`    varchar(64)      NOT NULL,
  `actor_id` varchar(16) CHARACTER SET ascii DEFAULT NULL,
  `nid`      varchar(16) CHARACTER SET ascii DEFAULT NULL,
  `ctime`    int(11)          NOT NULL DEFAULT unix_timestamp(),
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `uniq_actor_event` (`actor_id`, `event`),
  KEY        `idx_event`        (`event`),
  KEY        `idx_actor`        (`actor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;