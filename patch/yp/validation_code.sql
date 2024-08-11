-- NEW TABLE
-- DROP TABLE IF EXISTS `validation_code`;
CREATE TABLE `validation_code`(
    `sys_id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `id` VARBINARY(16) NOT NULL,
    `action` ENUM('delete_drumate_account','forgot_password'),
    `code` VARCHAR(255) NOT NULL,
    `expiry_time` INT(11) UNSIGNED NOT NULL DEFAULT 0,
    `ctime` INT(11) NOT NULL,
     PRIMARY KEY (`sys_id`),
     UNIQUE KEY (`id`, `action`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;