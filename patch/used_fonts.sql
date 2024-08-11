-- NEW TABLE
DROP TABLE IF EXISTS `used_fonts`;
CREATE TABLE `used_fonts`(
    `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(200) NOT NULL,
    `ctime` int(11) NOT NULL,
     PRIMARY KEY (`sys_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;