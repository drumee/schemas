DROP TABLE IF EXISTS `redirect_state`;
CREATE TABLE `redirect_state` (
  `sys_id` INT(10) unsigned NOT NULL AUTO_INCREMENT,
  `id`   VARCHAR(16),
  `metadata` JSON,
   UNIQUE KEY `id` (`id`),
   PRIMARY KEY (`sys_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4; 

