 Drop table if exists `corporate`;
 CREATE TABLE `corporate` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `owner_id` varchar(16) NOT NULL,
  `entity_id` varchar(16) NOT NULL,
  `expiry_time` int(11) NOT NULL DEFAULT '0',
  `status` enum('active','invite','delete') DEFAULT 'invite',  
  `ctime` int(11) DEFAULT NULL,
  `utime` int(11) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `pkey` (`owner_id`,`entity_id`),
  KEY `entity_id` (`entity_id`),
  KEY `owner_id` (`owner_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;


Drop table if exists `homework`;
CREATE TABLE `homework` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `home_id` varchar(16) NOT NULL,
  `work_id` varchar(16) NOT NULL,
  `ctime` int(11) DEFAULT NULL,
  `utime` int(11) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `pkey` (`home_id`,`work_id`),
  UNIQUE KEY `home_id` (`home_id`),  
  KEY `work_id` (`work_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;



ALTER TABLE drumate CHANGE category category enum('individual','professional','worker','corporate') DEFAULT 'individual';

