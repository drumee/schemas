CREATE TABLE `sessions` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varbinary(64) NOT NULL,
  `user_id` varchar(16) DEFAULT NULL,
  `username` varchar(64) NOT NULL DEFAULT '',
  `domain` varchar(128) NOT NULL DEFAULT 'drumee.net',
  `expire_time` int(11) NOT NULL DEFAULT 0,
  `update_time` int(11) NOT NULL DEFAULT 0,
  `start_time` int(11) NOT NULL DEFAULT 0,
  `ttl` int(11) NOT NULL DEFAULT 86400,
  `last_ip` varchar(64) NOT NULL DEFAULT '',
  `last_ip_fwd_for` varchar(40) NOT NULL DEFAULT '',
  `req_uri` varchar(255) NOT NULL DEFAULT '',
  `referer` varchar(64) NOT NULL DEFAULT '',
  `ua` varchar(64) NOT NULL DEFAULT '',
  `action` varchar(40) NOT NULL,
  `host_id` varchar(16) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`),
  KEY `user_id` (`user_id`),
  KEY `last_ip` (`last_ip`),
  KEY `ua` (`ua`),
  KEY `username` (`username`),
  KEY `referer` (`referer`),
  KEY `domain` (`domain`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
