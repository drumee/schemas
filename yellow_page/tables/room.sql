CREATE TABLE `room` (
  `hub_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `presenter_id` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `ctime` int(11) unsigned NOT NULL,
  `ttime` int(11) unsigned DEFAULT 0,
  `type` enum('webinar','meeting','connect','screen') DEFAULT 'meeting',
  `status` enum('waiting','started') DEFAULT 'waiting',
  PRIMARY KEY (`id`),
  UNIQUE KEY `hub_id` (`hub_id`,`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
