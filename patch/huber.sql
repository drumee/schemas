-- CREATE TABLE `huber` (
--   `id` varbinary(16) NOT NULL,
--   `privilege` tinyint(2) NOT NULL DEFAULT '0',
--   `ctime` int(11) NOT NULL,
--   PRIMARY KEY (`id`),
--   KEY `ctime` (`ctime`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
--
-- insert into huber select id, 63, unix_timestamp() from yp.entity where db_name=database() limit 1;

-- ALTER TABLE `huber` DROP PRIMARY KEY;
-- ALTER TABLE `huber` ADD UNIQUE(`id`);
-- ALTER TABLE `huber` ADD `sys_id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST;
-- ALTER TABLE `huber` ADD `expiry_time` INT(11) NOT NULL DEFAULT 0 AFTER `privilege`;
-- ALTER TABLE `huber` ADD `utime` INT(11) NULL AFTER `ctime`;

ALTER TABLE `huber` ADD `expiry_time` INT(11) NOT NULL DEFAULT 0 AFTER `privilege`;
-- ALTER TABLE `huber` ADD `utime` INT(11) NULL AFTER `ctime`;
 