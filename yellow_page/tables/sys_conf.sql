CREATE TABLE `sys_conf` (
  `conf_key` varchar(40) NOT NULL,
  `conf_value` longtext DEFAULT NULL,
  PRIMARY KEY (`conf_key`),
  FULLTEXT KEY `conf_value` (`conf_value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci
