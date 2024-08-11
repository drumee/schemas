
DROP TABLE `connection`;
CREATE TABLE `connection` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `session_id` varchar(64) DEFAULT NULL,
  `login_time` int(11) NOT NULL DEFAULT '0',
  `logout_time` int(11) NOT NULL DEFAULT '0',
  `ip` varchar(64) NOT NULL DEFAULT '',
  `ua` varchar(512) NOT NULL DEFAULT '',
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `session_id` (`session_id`),
  KEY `user_id` (`user_id`),
  KEY `ip` (`ip`),
  KEY `ua` (`ua`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
