-- NEW TABLE
-- DROP TABLE IF EXISTS `non_drumate`;
CREATE TABLE `non_drumate`(
    `sys_id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `id` VARBINARY(16) NOT NULL,
    `email` VARCHAR(500) NOT NULL,
    `firstname` VARCHAR(200) NULL,
    `lastname` VARCHAR(200) NULL,
    `mobile` VARCHAR(40) NULL,
    `extra` MEDIUMTEXT NULL,
    `privilege` VARCHAR(50) NULL,
    `token` VARCHAR(255) NOT NULL,
    `action` ENUM('add_contributor','add_contact', 'share_media') NOT NULL,
    `entity_id` VARCHAR(100) NOT NULL,
    `item_id` VARCHAR(100) NOT NULL,
    `expiry_time` INT(11) NOT NULL DEFAULT 0,
    `ctime` INT(11) NOT NULL,
     PRIMARY KEY (`sys_id`),
     UNIQUE KEY (`email`, `action`, `entity_id`, `item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;