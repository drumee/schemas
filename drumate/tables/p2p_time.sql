CREATE TABLE IF NOT EXISTS `p2p_time` (
  `peer_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `ref_ctime` int(11) unsigned DEFAULT NULL,
  `message` mediumtext DEFAULT NULL,
  `attachment` longtext DEFAULT NULL CHECK (json_valid(`attachment`)),
  `metadata` mediumtext DEFAULT NULL,
  `ctime` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`peer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;