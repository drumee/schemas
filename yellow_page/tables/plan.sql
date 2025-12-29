DROP TABLE IF EXISTS  `plan`;
CREATE TABLE `plan` (
  `sys_id` INT(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(30) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT 'Free',
  `price` INTEGER UNSIGNED DEFAULT 0,
  `capacity` JSON,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `name` (`name`)
)  ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
replace into plan (name, price, capacity) select 'free', 0, JSON_OBJECT('seat', 0, 'disk', 20000000000, 'organization', 0, 'history_length', 0, 'amin_role', 1, 'editor', 3);
replace into plan (name, price, capacity) select 'pro', 1699, JSON_OBJECT('seat', 5, 'disk', 50000000000, 'organization', 1, 'history_length', 7, 'amin_role', 1, 'editor', 5);