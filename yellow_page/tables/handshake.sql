
CREATE TABLE `handshake` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(64) NOT NULL,
  `ip` varchar(64) NOT NULL,
  `ctime` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
