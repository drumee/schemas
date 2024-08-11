-- CREATE TABLE `contact` ( `sys_id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT , `drumate_id` VARBINARY(16) NOT NULL , `firstname` VARCHAR(80) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL , `lastname` VARCHAR(80) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL , `email` VARCHAR(160) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL , `mobile` VARCHAR(40) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL , `address` VARCHAR(500) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL , `ext` VARCHAR(6000) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL , PRIMARY KEY (`sys_id`), INDEX (`drumate_id`), INDEX (`address`), INDEX (`email`), INDEX (`lastname`), INDEX (`firstname`)) ENGINE = InnoDB;

-- drop table contact;

-- ALTER TABLE `contact` ADD UNIQUE(`email`);
-- ALTER TABLE `contact` ADD UNIQUE(`drumate_id`);
-- ALTER TABLE `contact` MODIFY ext MEDIUMTEXT NOT NULL;
-- ALTER TABLE `contact` MODIFY email VARCHAR(160) NOT NULL;
-- ALTER TABLE `contact` MODIFY drumate_id VARBINARY(16) NULL;
-- ALTER TABLE `contact` MODIFY mobile VARCHAR(40) NOT NULL;
alter table contact add UNIQUE KEY `email` (`email`);
