-- One chat thread per file in a hub.
-- file_thread_id exposed to UI == root_message_id (the message_id of the
-- folder-visible "file.thread" system card in `channel`).
-- folder_nid is CREATION CONTEXT only; current folder membership follows
-- media.parent_id (see channel_file_thread_list_by_folder).
CREATE TABLE IF NOT EXISTS `file_thread` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `file_nid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `folder_nid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `root_message_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `created_by` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `last_message_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `reply_count` int(11) unsigned NOT NULL DEFAULT 0,
  `ctime` int(11) NOT NULL,
  `mtime` int(11) NOT NULL,
  `status` enum('active','deleted') NOT NULL DEFAULT 'active',
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `file_thread_file_uidx` (`file_nid`),
  UNIQUE KEY `file_thread_root_uidx` (`root_message_id`),
  KEY `file_thread_folder_idx` (`folder_nid`, `status`, `mtime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
