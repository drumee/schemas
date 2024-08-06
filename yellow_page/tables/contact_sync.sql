CREATE TABLE `contact_sync` (
  `sys_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `owner_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `uid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `status` enum('new','update','delete','ok','') NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `hub_iduid` (`uid`,`owner_id`),
  KEY `owner_id` (`owner_id`),
  KEY `uid` (`uid`),
  KEY `uidstatus` (`uid`,`status`),
  KEY `hub_idstatus` (`owner_id`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
