-- CREATE TABLE `fonts` ( `sys_id` INT NOT NULL AUTO_INCREMENT , `name` VARCHAR(1024) NULL DEFAULT NULL , `variant` VARCHAR(128) NULL DEFAULT NULL , `url` VARCHAR(1000) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL , PRIMARY KEY (`sys_id`), INDEX (`url`), UNIQUE (`name`)) ENGINE = InnoDB;
-- ALTER TABLE `style` ADD `status` ENUM('active', 'frozen') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'active' AFTER `url`, ADD `ctime` INT(11) NOT NULL AFTER `status`, ADD `mtime` INT(11) NOT NULL AFTER `ctime`;
-- rename table fonts to font;


-- ALTER TABLE `font` CHANGE `name` `name` VARCHAR(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL;
-- ALTER TABLE `font` CHANGE `url` `url` VARCHAR(1024) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL;

-- ALTER TABLE `font` ADD `family` VARCHAR(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL AFTER `sys_id`;

ALTER TABLE font DROP INDEX name;
update font set family=concat(name, ', ', variant);
ALTER TABLE `font` ADD UNIQUE(`family`);