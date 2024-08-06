CREATE TABLE `role` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(500) NOT NULL,
  `org_id` varchar(16) NOT NULL,
  `position` int(11) unsigned DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`org_id`,`name`),
  KEY `org_id` (`org_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
