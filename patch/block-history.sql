-- CREATE TABLE `block_history` (
--   `serial` int(10) NOT NULL AUTO_INCREMENT,
--   `path` varchar(1000) NOT NULL,
--   `master_id` varbinary(16) NOT NULL,
--   `device` enum('desktop','tablet','mobile') CHARACTER SET ascii NOT NULL DEFAULT 'desktop',
--   `status` enum('master','backup') CHARACTER SET ascii NOT NULL DEFAULT 'backup',
--   `meta` mediumtext NOT NULL,
--   PRIMARY KEY (`serial`),
--   UNIQUE KEY `path` (`path`),
--   KEY `device` (`device`),
--   KEY `status` (`status`),
--   FULLTEXT KEY `meta` (`meta`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ALTER TABLE `block_history` ADD `ctime` INT(11) UNSIGNED NOT NULL AFTER `meta`;
-- DROP TABLE IF EXISTS block_history;
-- DROP FUNCTION IF EXISTS `block_ident`;
-- CREATE TABLE `block_history` (
--   `serial` int(10) NOT NULL AUTO_INCREMENT,
--   `author_id` varbinary(16) NOT NULL,
--   `master_id` varbinary(16) NOT NULL,
--   `lang` varchar(10) CHARACTER SET ascii NOT NULL DEFAULT 'en',
--   `device` enum('desktop','tablet','mobile') CHARACTER SET ascii NOT NULL DEFAULT 'desktop',
--   `meta` mediumtext NOT NULL,
--   `ctime` int(11) unsigned NOT NULL,
--   PRIMARY KEY (`serial`),
--   KEY `lang` (`lang`),
--   KEY `device` (`device`),
--   FULLTEXT KEY `meta` (`meta`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
-- ALTER TABLE `block` DROP `device`;
-- ALTER TABLE `block` DROP `lang`;
-- ALTER TABLE `block` DROP `comment`;

-- ALTER TABLE `block` ADD `active` INT(6) NOT NULL DEFAULT '0' AFTER `serial`;

-- CREATE TABLE `tmtp` (
--   `serial` int(10) NOT NULL AUTO_INCREMENT,
--   `meta` mediumtext NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- ALTER TABLE `block` CHANGE `hashtag` `hashtag` VARCHAR(500) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL;
-- ALTER TABLE `block` ADD `conf` VARCHAR(600) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL AFTER `author_id`;
-- ALTER TABLE block DROP INDEX `hashtag`, ADD INDEX `hashtag` (`hashtag`) USING BTREE;

-- ALTER TABLE block DROP INDEX `conf`;
-- ALTER TABLE `block` ADD UNIQUE(`conf`);

-- ALTER TABLE `block` DROP `conf`;

ALTER TABLE block_history ADD COLUMN status enum('draft','history') NOT NULL DEFAULT 'history' AFTER device, ADD COLUMN isonline INT(4) DEFAULT 0 AFTER status;