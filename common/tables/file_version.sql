CREATE TABLE IF NOT EXISTS `file_version` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `nid` varchar(16) NOT NULL,
  `version_num` int(11) unsigned NOT NULL DEFAULT 1,
  `filename` varchar(255) NOT NULL DEFAULT '',
  `filesize` bigint(20) unsigned NOT NULL DEFAULT 0,
  `file_path` varchar(1000) NOT NULL DEFAULT '',
  `created_by` varchar(16) NOT NULL,
  `ctime` int(11) unsigned NOT NULL,
  `is_active` tinyint(1) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_nid` (`nid`),
  KEY `idx_is_active` (`nid`, `is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;