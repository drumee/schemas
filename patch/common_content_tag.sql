-- NEW TABLE
DROP TABLE IF EXISTS `content_tag`;
CREATE TABLE `content_tag`(
    `sys_id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `id` VARBINARY(16) NOT NULL,
    `language` VARCHAR(50) NOT NULL,
    `type` ENUM('block', 'folder', 'link', 'video', 'image', 'audio', 'document', 'stylesheet', 'other') NOT NULL,
    `status` ENUM('active') NOT NULL,
    `name` VARCHAR(500) NOT NULL,
    `ctime` INT(11) NOT NULL,
    PRIMARY KEY (`sys_id`),
    UNIQUE KEY (`id`, `name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
