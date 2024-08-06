CREATE TABLE `notification` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `share_id` varchar(50) DEFAULT NULL,
  `owner_id` varchar(16) NOT NULL,
  `resource_id` varchar(16) NOT NULL,
  `entity_id` varchar(512) NOT NULL,
  `message` mediumtext DEFAULT NULL,
  `expiry_time` int(11) NOT NULL DEFAULT 0,
  `permission` tinyint(4) unsigned NOT NULL,
  `status` enum('receive','accept','refuse','remove','change') DEFAULT 'receive',
  `ctime` int(11) DEFAULT NULL,
  `utime` int(11) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `pkey` (`resource_id`,`entity_id`),
  KEY `entity_id` (`entity_id`),
  KEY `owner_id` (`owner_id`),
  KEY `resource_id` (`resource_id`),
  KEY `permission` (`permission`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
