-- Per-user read cursor of one topic (the hub-wide read_channel cursor would
-- clear every topic at once).
CREATE TABLE IF NOT EXISTS `channel_topic_read` (
  `uid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `topic_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `ref_sys_id` int(11) unsigned NOT NULL DEFAULT 0,
  `ctime` int(11) NOT NULL,
  PRIMARY KEY (`uid`, `topic_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
