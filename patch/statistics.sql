-- NEW TABLE
DROP TABLE IF EXISTS `statistics`;
CREATE TABLE `statistics`(
    `sys_id` INT(11) unsigned NOT NULL AUTO_INCREMENT,
    `disk_usage` INT(8) UNSIGNED NOT NULL DEFAULT 0,
    `page_count` INT(8) NOT NULL DEFAULT 0,
    `visit_count` INT(8) NOT NULL DEFAULT 0,
    `ctime` INT(11) NOT NULL,
     PRIMARY KEY (`sys_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;