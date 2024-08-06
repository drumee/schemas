CREATE TABLE `dmz_userx` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) NOT NULL,
  `email` varchar(512) NOT NULL,
  `name` varchar(80) DEFAULT NULL,
  `hub_id` varchar(128) DEFAULT NULL,
  `fingerprint` varchar(128) DEFAULT NULL,
  `token` varchar(128) DEFAULT NULL,
  `nid` varchar(128) DEFAULT NULL,
  `notify_at` int(11) DEFAULT 0,
  `is_sync` int(4) DEFAULT 0,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `email` (`email`,`hub_id`,`id`,`nid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
