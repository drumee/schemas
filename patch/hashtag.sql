CREATE TABLE IF NOT EXISTS `article` (
  `id` varbinary(16) NOT NULL,
  `author_id` varbinary(16) NOT NULL,
  `summary` text CHARACTER SET utf8mb4 NOT NULL,
  `content` mediumtext CHARACTER SET utf8mb4 NOT NULL,
  `draft` mediumtext CHARACTER SET utf8mb4 NOT NULL,
  `create_time` int(11) unsigned NOT NULL DEFAULT '0',
  `publish_time` int(11) unsigned NOT NULL DEFAULT '0',
  `edit_time` int(11) unsigned NOT NULL DEFAULT '0',
  `rating` double NOT NULL DEFAULT '0',
  `lang` varchar(10) CHARACTER SET utf8 NOT NULL DEFAULT '',
  `status` enum('online','offline','draft','trash','archive') CHARACTER SET utf8 NOT NULL DEFAULT 'draft',
  `version` int(10) unsigned NOT NULL DEFAULT '0',
  `counter` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `author_id` (`author_id`),
  KEY `create_time` (`create_time`),
  KEY `publish_time` (`publish_time`),
  KEY `status` (`status`),
  FULLTEXT KEY `content` (`content`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


-- DRUMATE TABLES TO BE REMOVED

-- CREATE  TABLE IF NOT EXISTS `hashtag` (
--   `label` varchar(100) CHARACTER SET utf8mb4 NOT NULL,
--   `hash_id` varbinary(16) NOT NULL,
--   `ctime` int(11) NOT NULL,
--   `mtime` int(11) NOT NULL,
--   KEY `label` (`label`,`hash_id`),
--   KEY `ctime` (`ctime`,`mtime`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
-- 
-- CREATE TABLE IF NOT EXISTS `preferences` (
--   `name` varchar(40) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL DEFAULT '',
--   `user_id` varbinary(16) NOT NULL,
--   `last_tab` varchar(255) CHARACTER SET utf8 NOT NULL DEFAULT 'home',
--   `home_tab` varchar(255) CHARACTER SET utf8 NOT NULL DEFAULT 'home',
--   `general` longtext CHARACTER SET utf8 NOT NULL,
--   `privacy` longtext CHARACTER SET utf8 NOT NULL,
--   `security` longtext CHARACTER SET utf8 NOT NULL,
--   `mobile` longtext CHARACTER SET utf8 NOT NULL,
--   `jason` longtext CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
--   FULLTEXT KEY `general` (`general`,`privacy`,`security`,`mobile`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
-- 
-- 
-- 
-- CREATE TABLE IF NOT EXISTS `profile` (
--   `user_id` varbinary(16) NOT NULL,
--   `username` varchar(40) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL DEFAULT '',
--   `password` varchar(40) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL DEFAULT '',
--   `pseudo` varchar(80) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL DEFAULT '',
--   `firstname` varchar(80) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL DEFAULT '',
--   `secondname` varchar(80) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL DEFAULT '',
--   `nickname` varchar(80) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL DEFAULT '',
--   `first_use` tinyint(1) NOT NULL,
--   `lastname` varchar(40) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL DEFAULT '',
--   `email` varchar(120) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL DEFAULT '',
--   `photo_pub` varchar(255) CHARACTER SET utf8 NOT NULL,
--   `photo_res` varchar(255) CHARACTER SET utf8 NOT NULL,
--   `photo_prv` varchar(255) CHARACTER SET utf8 NOT NULL,
--   `alt_email` varchar(120) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL DEFAULT '',
--   `gender` enum('M','F') CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
--   `birthdate` varchar(255) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL DEFAULT '',
--   `residence_city` varchar(40) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL DEFAULT '',
--   `postcode` tinyint(4) unsigned NOT NULL DEFAULT '0',
--   `personal_data` longtext CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
--   PRIMARY KEY (`user_id`),
--   UNIQUE KEY `username` (`username`),
--   UNIQUE KEY `email` (`email`),
--   KEY `postcode` (`postcode`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

