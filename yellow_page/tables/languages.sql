CREATE TABLE `languages` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `key_code` varchar(40) NOT NULL,
  `category` varchar(40) DEFAULT NULL,
  `lng` varchar(20) NOT NULL,
  `des` text NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`key_code`,`category`,`lng`),
  KEY `key_code` (`key_code`),
  KEY `category` (`category`),
  KEY `lng` (`lng`),
  FULLTEXT KEY `des` (`des`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
