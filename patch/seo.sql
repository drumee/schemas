-- DROP TABLE IF EXISTS seo;

-- CREATE TABLE seo ( `sys_id` INT NOT NULL AUTO_INCREMENT , `hashtag` VARCHAR(256) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL , `lang` VARCHAR(6) NOT NULL , `content` MEDIUMTEXT NOT NULL , PRIMARY KEY (`sys_id`), INDEX (`hashtag`), INDEX (`lang`), FULLTEXT (`content`)) ENGINE = InnoDB;

-- ALTER TABLE `seo` ADD `key` VARCHAR(25) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL AFTER `sys_id`, ADD UNIQUE (`key`);

-- ALTER TABLE `seo` CHANGE `content` `content` VARCHAR(25) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL;

-- ALTER TABLE `seo` CHANGE `content` `content` MEDIUMTEXT CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

-- ALTER TABLE `seo` DROP INDEX `hashtag`, ADD FULLTEXT `hashtag` (`hashtag`);

ALTER TABLE `seo` ADD `link_data` MEDIUMTEXT CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL AFTER `content`;