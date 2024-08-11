CREATE TABLE `header`(
    `sys_id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `id` VARBINARY(16) NOT NULL,
    `language` VARCHAR(50) NOT NULL,
    `icon` VARCHAR(500) NOT NULL,
    `title` VARCHAR(500) NOT NULL,
    `keywords` VARCHAR(500) NOT NULL,
    PRIMARY KEY (`sys_id`),
    UNIQUE KEY (`id`, `language`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
