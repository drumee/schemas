DROP TABLE IF EXISTS  `channel`;
CREATE TABLE IF NOT EXISTS `channel` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `author_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `message` mediumtext DEFAULT NULL,
  `message_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `thread_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `file_thread_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `attachment` longtext DEFAULT NULL CHECK (json_valid(`attachment`)),
  `is_forward` tinyint(1) DEFAULT 0,
  `mention_ids` JSON NULL,
  `status` enum('draft','active','trashed') NOT NULL DEFAULT 'active',
  `ctime` int(11) NOT NULL,
  `metadata`    mediumtext DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `message_id` (`message_id`),
  KEY `channel_file_thread_idx` (`file_thread_id`, `sys_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;