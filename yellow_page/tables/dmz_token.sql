CREATE TABLE `dmz_token` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(80) NOT NULL,
  `hub_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `node_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `guest_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `fingerprint` varchar(128) DEFAULT NULL,
  `is_sync` int(4) DEFAULT 0,
  `notify_at` int(11) DEFAULT 0,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `recipient` (`hub_id`,`node_id`,`guest_id`),
  KEY `idx_guest_id` (`guest_id`),
  KEY `idx_guest_id_is_sync` (`guest_id`,`is_sync`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
