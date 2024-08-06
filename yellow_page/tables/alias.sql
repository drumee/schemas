CREATE TABLE `alias` (
  `sn` int(6) NOT NULL AUTO_INCREMENT,
  `id` varbinary(16) NOT NULL,
  `ident` varchar(40) NOT NULL DEFAULT '',
  `vhost` varchar(250) NOT NULL,
  `scope` enum('alternate','user','main') NOT NULL,
  `domain` varchar(128) NOT NULL,
  PRIMARY KEY (`sn`),
  UNIQUE KEY `vhost` (`vhost`),
  UNIQUE KEY `sn` (`sn`),
  KEY `scope` (`scope`),
  KEY `domain` (`domain`),
  KEY `ident` (`ident`),
  KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
