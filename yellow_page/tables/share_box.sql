CREATE TABLE `share_box` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) NOT NULL,
  `owner_id` varchar(16) NOT NULL,
  `root_id` varchar(16) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `owner_id` (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
