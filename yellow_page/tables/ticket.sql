CREATE TABLE `ticket` (
  `ticket_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `message_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `uid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `metadata` longtext DEFAULT NULL CHECK (json_valid(`metadata`)),
  `status` varchar(15) GENERATED ALWAYS AS (json_unquote(json_extract(`metadata`,'$.status'))) VIRTUAL,
  `utime` int(11) NOT NULL,
  `last_sys_id` int(11) DEFAULT 0,
  PRIMARY KEY (`ticket_id`),
  UNIQUE KEY `message_id` (`message_id`),
  UNIQUE KEY `id` (`uid`,`ticket_id`),
  KEY `last_sys_id` (`last_sys_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
