CREATE TABLE IF NOT EXISTS `tag` (
  `label` varchar(100) CHARACTER SET utf8mb4 NOT NULL,
  `hash_id` varbinary(16) NOT NULL,
  KEY `label` (`label`,`hash_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
