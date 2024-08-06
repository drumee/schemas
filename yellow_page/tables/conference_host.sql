CREATE TABLE `conference_host` (
  `hub_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `conference_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `presenter_id` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `ctime` int(11) unsigned NOT NULL,
  `ttime` int(11) unsigned DEFAULT 0,
  `type` enum('webinar','meeting','connect','screen') DEFAULT 'meeting',
  `status` enum('waiting','started') DEFAULT 'waiting',
  PRIMARY KEY (`conference_id`),
  UNIQUE KEY `hub_id` (`hub_id`,`type`),
  UNIQUE KEY `presenter_id` (`presenter_id`,`hub_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
