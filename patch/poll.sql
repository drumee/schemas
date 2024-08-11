-- CREATE TABLE `poll` ( `id` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL , `ident` VARCHAR(80) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL , `name` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL , `ctime` INT NOT NULL , PRIMARY KEY (`id`), UNIQUE (`ident`), FULLTEXT `name` (`name`)) ENGINE = MyISAM;

-- ALTER TABLE `poll` ADD `referer` VARCHAR(500) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL AFTER `ctime`, ADD `ip` VARCHAR(80) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL AFTER `referer`, ADD INDEX (`referer`), ADD FULLTEXT (`ip`);

ALTER TABLE `poll` ADD `author_id` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL AFTER `id`, ADD INDEX (`author_id`);
