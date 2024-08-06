CREATE TABLE `delete_channel` (
  `uid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `ref_sys_id` int(11) unsigned NOT NULL,
  `ctime` int(11) NOT NULL,
  UNIQUE KEY `id` (`uid`,`ref_sys_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
