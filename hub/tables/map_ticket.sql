CREATE TABLE `map_ticket` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `message_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `ticket_id` int(11) unsigned NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`message_id`,`ticket_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
