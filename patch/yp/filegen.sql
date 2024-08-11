
CREATE TABLE `filegen` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `key` varchar(64) CHARACTER SET ascii NOT NULL DEFAULT 'bin',
  `extension` varchar(16) CHARACTER SET ascii NOT NULL DEFAULT 'bin',
  `category` varchar(16) CHARACTER SET ascii NOT NULL DEFAULT 'other',
  `mimetype` varchar(512) CHARACTER SET ascii NOT NULL DEFAULT 'unknown',
  `capability` varchar(8) CHARACTER SET ascii NOT NULL DEFAULT '---',
  `description` varchar(512) CHARACTER SET utf8 NOT NULL DEFAULT '*',
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `key` (`key`),
  UNIQUE KEY `extension` (`extension`),
  KEY `category` (`category`,`mimetype`,`capability`),
  FULLTEXT KEY `description` (`description`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;