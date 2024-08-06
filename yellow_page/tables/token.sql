CREATE TABLE `token` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `email` varchar(512) DEFAULT NULL,
  `name` varchar(512) DEFAULT NULL,
  `secret` varchar(255) NOT NULL,
  `method` varchar(80) DEFAULT NULL,
  `inviter_id` varchar(16) DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'active',
  `ctime` int(11) unsigned DEFAULT NULL,
  `expiry` int(11) unsigned DEFAULT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `secret` (`secret`),
  UNIQUE KEY `purpose` (`email`,`method`,`inviter_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
