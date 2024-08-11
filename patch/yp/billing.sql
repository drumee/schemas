CREATE TABLE `billing` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` varchar(16) NOT NULL,
  `product_code` varchar(16) NOT NULL,
  `amount` float DEFAULT 0,
  `ctime` int(11) DEFAULT NULL,
  `utime` int(11) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `pkey` (`user_id`,`product_code`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8;

CREATE TABLE `product` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(16) NOT NULL,
  `version` varchar(20) NOT NULL,
  `ctime` int(11) DEFAULT NULL,
  `utime` int(11) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8;

CREATE TABLE `disk_usage` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `hub_id` varchar(16) NOT NULL,
  `size` int(11) DEFAULT 0,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `hub_id` (`hub_id`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8;

