CREATE TABLE IF NOT EXISTS `p2p_read` (
  `peer_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `uid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `ref_ctime` int(11) unsigned NOT NULL DEFAULT 0,
  `ctime` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`peer_id`, `uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;