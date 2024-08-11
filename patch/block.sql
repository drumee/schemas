-- ALTER TABLE `block` DROP `context`;
-- ALTER TABLE `block` DROP `tag`;
-- ALTER TABLE `block` DROP `hash`;
-- ALTER TABLE `block` DROP `author`;
-- ALTER TABLE `block` DROP `content`;
-- ALTER TABLE `block` DROP `footnote`;
-- ALTER TABLE `block` DROP `backup`;
-- ALTER TABLE `block` DROP `newbie`;
-- ALTER TABLE `block` DROP `expert`;
-- ALTER TABLE `block` CHANGE `device` `device` ENUM('desktop','tablet','mobile') CHARACTER SET ascii COLLATE ascii_general_ci NULL DEFAULT 'desktop';
-- ALTER TABLE `block` CHANGE `lang` `lang` VARCHAR(10) CHARACTER SET ascii COLLATE ascii_general_ci NULL DEFAULT 'en';

-- ALTER TABLE `block` CHANGE `status` `status` ENUM('active','deleted','locked','backup','readonly','draft','latest') CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT 'latest';

-- ALTER TABLE `block` ADD `master_id` VARBINARY(16) NOT NULL AFTER `id`;
-- update block set master_id=id;

-- ALTER TABLE `block` CHANGE `status` `status` ENUM('online','offline','locked') CHARACTER SET ascii COLLATE ascii_general_ci NULL DEFAULT 'online';

-- ALTER TABLE `block` ADD `status2` ENUM('online', 'offline', 'locked', 'readonly') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'online' AFTER `status`;

-- ALTER TABLE `block` DROP `status`;

-- ALTER TABLE `block` CHANGE `status2` `status` ENUM('online','offline','locked','readonly') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'online';

-- ALTER TABLE `block` DROP `master_id`;

-- ALTER TABLE block DROP INDEX id_3;
-- ALTER TABLE block DROP INDEX id_4;


-- ROP TABLE IF EXISTS `block`;
-- REATE TABLE `block` (
--  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
--  `id` varbinary(16) NOT NULL,
--  `serial` int(6) unsigned NOT NULL DEFAULT '0',
--  `active` int(6) NOT NULL DEFAULT '0',
--  `author_id` varbinary(16) NOT NULL,
--  `hashtag` varchar(500) CHARACTER SET ascii NOT NULL,
--  `type` enum('page','block','menu','header','footer') NOT NULL DEFAULT 'block',
--  `editor` enum('creator','designer') CHARACTER SET ascii NOT NULL DEFAULT 'creator',
--  `status` enum('online','offline','locked','readonly') CHARACTER SET ascii NOT NULL DEFAULT 'online',
--  `ctime` int(11) NOT NULL,
--  `mtime` int(11) NOT NULL,
--  `version` varchar(10) NOT NULL DEFAULT '1.0.0',
--  PRIMARY KEY (`sys_id`),
--  UNIQUE KEY `id` (`id`),
--  KEY `ctime` (`ctime`),
--  KEY `mtime` (`mtime`),
--  KEY `version` (`version`),
--  KEY `author_id` (`author_id`),
--  KEY `editor` (`editor`),
--  KEY `hashtag` (`hashtag`) USING BTREE
--  ENGINE=InnoDB AUTO_INCREMENT=125 DEFAULT CHARSET=utf8 ;
-- nsert into block select null, id, 1, 1, author_id, hashtag, 'page', 'designer', 'offline', ctime, mtime, version from layout;


-- ALTER TABLE `block` DROP INDEX `hashtag`, DROP INDEX `hashtag_2`, ADD UNIQUE `hashtag` (`hashtag`) USING BTREE;
-- ALTER TABLE `block` CHANGE `type` `type` ENUM('page','block','menu','header','footer', 'section')  CHARACTER SET ascii COLLATE ascii_general_ci;

