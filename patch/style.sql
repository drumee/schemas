-- DROP TABLE IF EXISTS `style`;
-- CREATE TABLE `style` ( `id` INT(8) NOT NULL AUTO_INCREMENT , `className` VARCHAR(255) CHARACTER SET ascii COLLATE ascii_bin NOT NULL , `attributes` JSON , `comment` VARCHAR(255) NOT NULL , PRIMARY KEY (`id`), INDEX (`className`)) ENGINE = InnoDB;

-- ALTER TABLE `style` CHANGE `comment` `comment` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT 'xxx';

-- ALTER TABLE `style` CHANGE `className` `selector` VARCHAR(255) CHARACTER SET ascii COLLATE ascii_bin NOT NULL;

-- ALTER TABLE `style` CHANGE `attributes` `declaration` TEXT NULL DEFAULT NULL;


-- ALTER TABLE `style` CHANGE `attributes` `declaration` VARCHAR(10000) NULL DEFAULT NULL;

-- ALTER TABLE `style` ADD `status` ENUM('active', 'frozen') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'active';


-- ALTER TABLE `style` ADD `name` VARCHAR(80) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT 'My Style' AFTER `id`, ADD INDEX (`name`);

-- ALTER TABLE `style` ADD `class_name` VARCHAR(100) NOT NULL AFTER `name`;
ALTER TABLE `style` CHANGE `className` `class_name` VARCHAR(100);
