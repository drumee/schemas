ALTER TABLE  `params` ADD INDEX  `field` (  `field` );
ALTER TABLE  `params` ADD INDEX  `category` (  `category` );
ALTER TABLE  `params` ADD INDEX  `type` (  `type` );

DROP TABLE IF EXISTS `tag`;
CREATE TABLE IF NOT EXISTS `tag` (
  `label` varchar(100) CHARACTER SET utf8mb4 NOT NULL,
  `hash_id` varbinary(16) NOT NULL,
  KEY `label` (`label`,`hash_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

ALTER TABLE  `tag` ADD  `ctime` INT( 11 ) NOT NULL ,
ADD  `mtime` INT( 11 ) NOT NULL ,
ADD INDEX (  `ctime` ,  `mtime` );