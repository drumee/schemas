-- DROP TABLE IF EXISTS `message`;
-- CREATE TABLE `message` (
--   `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
--   `id` VARBINARY(16) NOT NULL ,
--   `email` VARCHAR(500) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL ,
--   `firstname` VARCHAR(80),
--   `lastname` VARCHAR(80),
--   `content` VARCHAR(1000),
--   `ctime` INT(11) NOT NULL ,
--   `referer` VARCHAR(500),
--   `ip` VARCHAR(50),
--   PRIMARY KEY (`sys_id`),
--   UNIQUE KEY `id` (`id`),
--   INDEX `name` (`firstname`,`lastname`,`email`),
--   INDEX (`ctime`),
--   INDEX (`referer`),
--   INDEX (`ip`),
--   FULLTEXT key `content`(`content`)
-- )ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE utf8_general_ci;


-- ALTER TABLE `message` ADD `type` ENUM('form', 'chat', 'drum', 'email') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL AFTER `id`, ADD `from` VARCHAR(512) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL AFTER `type`, ADD `to` VARCHAR(512) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL AFTER `from`;

ALTER TABLE `message` CHANGE `content` `content` VARCHAR(3000) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL;