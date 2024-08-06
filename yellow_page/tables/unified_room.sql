CREATE TABLE `unified_room` (
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `uid` varchar(30) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `is_mic_enabled` tinyint(4) DEFAULT 1,
  `is_video_enabled` tinyint(4) DEFAULT 0,
  `is_share_enabled` tinyint(4) DEFAULT 0,
  `is_write_enabled` tinyint(4) DEFAULT 0,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT '{}' CHECK (json_valid(`metadata`)),
  PRIMARY KEY (`uid`),
  UNIQUE KEY `id` (`id`,`uid`),
  KEY `idx_id` (`id`),
  KEY `idx_uid` (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
