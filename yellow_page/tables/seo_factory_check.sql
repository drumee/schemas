CREATE TABLE `seo_factory_check` (
  `sys_id` int(11) NOT NULL AUTO_INCREMENT,
  `hub_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `nid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `mfs_root` varchar(1000) DEFAULT NULL,
  `db_name` varchar(255) DEFAULT NULL,
  `file_path` varchar(5000) DEFAULT NULL,
  `extension` varchar(100) DEFAULT NULL,
  `mimetype` varchar(100) DEFAULT NULL,
  `category` varchar(16) DEFAULT NULL,
  `isprocessed` tinyint(2) unsigned NOT NULL DEFAULT 0,
  `ctime` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `key` (`hub_id`,`nid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
