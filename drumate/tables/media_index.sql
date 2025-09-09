DROP TABLE IF EXISTS  `media_index`;
CREATE TABLE `media_index` (
  `hub_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `home_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `actual_home_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `pid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `nid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `md5Hash` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `area` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `filetype` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `ext` varchar(100) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `status` varchar(100) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT 'active',
  `isalink` BOOLEAN DEFAULT 0,
  `privilege` int(4),
  `filesize`  bigint(20) unsigned DEFAULT 0,
  `filename`  varchar(100) NOT NULL,
  `filepath` varchar(1000) NOT NULL,
  `ownpath` varchar(1000) NOT NULL,
  `mtime` int(11) DEFAULT UNIX_TIMESTAMP(),
  `ctime` int(11) DEFAULT UNIX_TIMESTAMP(),
  `timestamp` int(11) DEFAULT UNIX_TIMESTAMP(),
  PRIMARY KEY `nid` (`hub_id`, `nid`),
  FULLTEXT KEY `content` (`filepath`, `filename`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
