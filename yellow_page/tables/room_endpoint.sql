CREATE TABLE `room_endpoint` (
  `room_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `ctime` int(11) unsigned NOT NULL,
  `server` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `location` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  UNIQUE KEY `room_id` (`room_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
