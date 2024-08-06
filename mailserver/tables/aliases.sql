DROP TABLE IF EXISTS `aliases`;
CREATE TABLE `aliases` (
  `id` int(6) NOT NULL AUTO_INCREMENT,
  `domain_id` int(6) NOT NULL,
  `source` varchar(100) NOT NULL,
  `destination` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `alias` (`source`,`destination`),
  KEY `aliases_ibfk_1` (`domain_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;