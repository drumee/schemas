CREATE TABLE `cookie` (
  `id` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `uid` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `ctime` int(11) NOT NULL DEFAULT 0,
  `mtime` int(11) NOT NULL DEFAULT 0,
  `ua` mediumtext NOT NULL DEFAULT '',
  `guest_name` varchar(128) DEFAULT NULL,
  `ttl` int(11) NOT NULL DEFAULT 86400,
  `failed` tinyint(4) unsigned DEFAULT 0,
  `status` varchar(64) DEFAULT NULL,
  `mimicker` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
