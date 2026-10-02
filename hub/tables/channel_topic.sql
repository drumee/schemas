-- A named sub-conversation of ONE folder's team chat. A message belongs to it
-- through channel.metadata._topic_id (as it belongs to a folder through
-- _scope_nid), so the channel table itself is not altered.
CREATE TABLE IF NOT EXISTS `channel_topic` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `folder_nid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `name` varchar(128) NOT NULL,
  `emoji` varchar(16) NOT NULL,
  `created_by` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `ctime` int(11) NOT NULL,
  `mtime` int(11) NOT NULL,
  `status` enum('active','deleted') NOT NULL DEFAULT 'active',
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `channel_topic_id_uidx` (`id`),
  KEY `channel_topic_folder_idx` (`folder_nid`, `status`, `sys_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
