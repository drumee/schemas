
CREATE TABLE IF NOT EXISTS `language`(
    `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
    `base` VARCHAR(10) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `locale` VARCHAR(100) NOT NULL,
	  `state` ENUM('deleted', 'active', 'frozen', 'replaced') NOT NULL,
    `ctime` int(11) NOT NULL,
    `mtime` int(11) NOT NULL,
     PRIMARY KEY (`sys_id`),
     INDEX  `base` (`base`),
     UNIQUE  `locale` (`locale`),
     INDEX  `name`(`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
