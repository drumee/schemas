-- NEW TABLE
DROP TABLE IF EXISTS `used_colors`;
CREATE TABLE `used_colors`(
    `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
    `rgba` VARCHAR(50) NOT NULL,
    `hexacode` VARCHAR(20) NOT NULL,
    `ctime` int(11) NOT NULL,
     PRIMARY KEY (`sys_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
