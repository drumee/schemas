-- DROP TABLE IF EXISTS `licence`;
-- CREATE TABLE `licence` (
--   `id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
--   `key` varchar(128),
--   `customer_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
--   `start` INTEGER(11) UNSIGNED,
--   `end` INTEGER(11) UNSIGNED,
--   `status` enum('pending','active','expired','revoked', 'exception'),
--   PRIMARY KEY `id` (`id`)
-- ) ENGINE=InnoDB ;

DROP TABLE IF EXISTS `licence`;
CREATE TABLE `licence` (
  `id` varchar(16) NOT NULL,
  `key` varchar(128) DEFAULT NULL,
  `domain` varchar(1000) NOT NULL,
  `customer_id` varchar(16) NOT NULL,
  `reseller_id` varchar(16) NOT NULL,
  `number_of_bays` tinyint(4) NOT NULL,
  `ctime` int(11) unsigned DEFAULT NULL,  -- creation
  `atime` int(11) unsigned DEFAULT NULL,  -- activation 
  `rtime` int(11) unsigned DEFAULT NULL,  -- revocation
  `status` enum('trial','active','expired','revoked','exception') DEFAULT 'trial',
  `signature` text NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=ascii COLLATE=ascii_general_ci;