CREATE TABLE IF NOT EXISTS `stripe_event` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `event_id` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `type` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `received_at` int(11) unsigned NOT NULL,
  `processed_at` int(11) unsigned DEFAULT NULL,
  `payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`payload`)),
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `event_id` (`event_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
