CREATE TABLE `device_registation` (
  `device_id` varchar(200) NOT NULL,
  `device_type` enum('ios','android','web') NOT NULL,
  `push_token` text NOT NULL,
  `uid` varchar(16) DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'active',
  `ctime` int(11) NOT NULL DEFAULT 0,
  `mtime` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`device_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
