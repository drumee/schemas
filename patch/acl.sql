-- ALTER TABLE  `acl` CHANGE  `permission`  `permission` TINYINT( 4 ) UNSIGNED NOT NULL;
-- update acl set permission=1;

-- ALTER TABLE `acl` CHANGE `resource_type` `resource_type` ENUM('media','comment','link','layout','all', '*') CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '*';

ALTER TABLE `acl` DROP PRIMARY KEY;
ALTER TABLE `acl` ADD UNIQUE(`pkey`);
ALTER TABLE `acl` ADD `sys_id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST;