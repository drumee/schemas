-- /* 
-- Structure :  https://datatracker.ietf.org/doc/rfc5774/ 
-- country : 2 alpha https://en.wikipedia.org/wiki/ISO_3166-1
-- entity_id : customer or company id
-- */
-- DROP TABLE IF EXISTS `address`;
-- -- CREATE TABLE `address` (
-- --   `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
-- --   `entity_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL, 
-- --   `country` varchar(20), 
-- --   `state` varchar(20),
-- --   `road_name` varchar(128),
-- --   `lot_number` varchar(128),
-- --   `local_name` varchar(128),
-- --   `floor` varchar(128),
-- --   `postal_code` INTEGER,
-- --   PRIMARY KEY `sys_id` (`sys_id`)
-- -- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;