
ALTER TABLE article DROP PRIMARY KEY;
ALTER TABLE article ADD UNIQUE(`id`);
ALTER TABLE article ADD `sys_id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST;
ALTER TABLE article ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;