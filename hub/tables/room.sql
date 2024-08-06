CREATE TABLE `room` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `session_id` varchar(16) NOT NULL,
  `user_id` varchar(16) NOT NULL,
  `socket_id` varchar(32) NOT NULL,
  `ctime` int(11) unsigned NOT NULL,
  `role` enum('organizer','attendee') DEFAULT 'organizer',
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `user_id` (`session_id`, `user_id`),
  UNIQUE KEY `socket_id` (`socket_id`)
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8mb4;