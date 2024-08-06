CREATE TABLE `site` (
  `id` varchar(16) NOT NULL,
  `owner_id` varbinary(16) NOT NULL,
  `dmail` varchar(255) NOT NULL DEFAULT '',
  `name` varchar(80) NOT NULL,
  `ctime` int(11) NOT NULL,
  `photo` varchar(255) NOT NULL,
  `mtime` int(11) NOT NULL,
  `autojoin` varchar(8) NOT NULL DEFAULT 'off',
  `description` text NOT NULL,
  `keywords` text NOT NULL,
  `permission` tinyint(4) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `dmail` (`dmail`),
  KEY `default_perm` (`permission`),
  KEY `owner_id` (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
