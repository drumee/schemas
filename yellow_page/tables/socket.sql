CREATE TABLE `socket` (
  `id` varchar(32) NOT NULL,
  `uid` varchar(32) NOT NULL DEFAULT '*',
  `cookie` varchar(64) DEFAULT NULL,
  `ctime` int(11) NOT NULL DEFAULT 0,
  `server` varchar(256) DEFAULT NULL,
  `location` varchar(256) DEFAULT NULL,
  `state` enum('active','idle') DEFAULT 'active',
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`),
  KEY `idx_server` (`server`),
  KEY `idx_id_state` (`id`,`state`),
  KEY `idx_state_ctime` (`state`,`ctime`)
) ENGINE=InnoDB DEFAULT CHARSET=ascii COLLATE=ascii_general_ci
