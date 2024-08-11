ALTER TABLE `language` ADD `state` ENUM('active','deleted') NOT NULL DEFAULT 'deleted' AFTER `locale`;
ALTER TABLE `language` ADD `flag_image` VARCHAR(200) NULL AFTER `locale`;