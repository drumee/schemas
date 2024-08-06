CREATE TABLE `services_log` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT 'index',
  `args` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`args`)),
  `uid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `hub_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `headers` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`headers`)),
  `ctime` int(11) unsigned NOT NULL,
  PRIMARY KEY (`sys_id`),
  KEY `uid` (`uid`),
  KEY `hub_id` (`hub_id`),
  KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
