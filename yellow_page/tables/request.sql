CREATE TABLE `request` (
  `sn` int(6) unsigned NOT NULL AUTO_INCREMENT,
  `firstname` varchar(255) NOT NULL,
  `lastname` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `id` varbinary(80) NOT NULL,
  `message` text NOT NULL,
  `reason` enum('request','presub','subscribe') NOT NULL DEFAULT 'request',
  `ident` varchar(255) NOT NULL,
  `tstamp` int(11) NOT NULL,
  PRIMARY KEY (`sn`),
  KEY `name` (`firstname`(128),`lastname`(128)),
  KEY `email` (`email`),
  KEY `ident` (`ident`),
  FULLTEXT KEY `message` (`message`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci
