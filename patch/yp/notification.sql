 Drop table if exists `notification`;
 CREATE TABLE `notification` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `owner_id` varchar(16) NOT NULL,
  `resource_id` varchar(16) NOT NULL,
  `entity_id` varchar(512) NOT NULL,
  `message` mediumtext  DEFAULT NULL,
  `expiry_time` int(11) NOT NULL DEFAULT '0',
  `permission` tinyint(4) unsigned NOT NULL,
  `status` enum('receive','accept','refuse','remove','change') DEFAULT 'receive',  
  `ctime` int(11) DEFAULT NULL,
  `utime` int(11) DEFAULT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `pkey` (`resource_id`,`entity_id`),
  KEY `entity_id` (`entity_id`),
  KEY `owner_id` (`owner_id`),
  KEY `resource_id` (`resource_id`),
  KEY `permission` (`permission`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;


ALTER TABLE notification ADD share_id varchar(16) NOT NULL AFTER sys_id;
UPDATE notification SET share_id = uniqueId();
ALTER TABLE notification ADD CONSTRAINT share_id UNIQUE (share_id);

ALTER TABLE notification drop index share_id;
ALTER TABLE notification modify share_id varchar(50) NULL;
