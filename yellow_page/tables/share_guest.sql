CREATE TABLE `share_guest` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `hub_id` varchar(16) NOT NULL,
  `email` varchar(512) NOT NULL,
  `permission` tinyint(4) unsigned NOT NULL,
  `expiry_time` int(11) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `share_guest` (`hub_id`,`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
