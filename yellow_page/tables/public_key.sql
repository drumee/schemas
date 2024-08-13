

CREATE TABLE `public_key` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` varchar(16) NOT NULL,
  `key` varchar(512) NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8;
