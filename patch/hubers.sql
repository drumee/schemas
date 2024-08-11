-- DROP TABLE `hubers`;
-- CREATE TABLE `huber` ( `id` VARBINARY(16) NOT NULL , `privilege` TINYINT(2) NOT NULL DEFAULT '0' , PRIMARY KEY (`id`)) ENGINE = InnoDB;
-- insert IGNORE into huber select * from members;

ALTER TABLE `huber` ADD `ctime` INT(11) NOT NULL AFTER `privilege`, ADD INDEX (`ctime`);