
DROP TABLE IF EXISTS `pod`;
CREATE TABLE `pod` (
  `id` INT(11) unsigned NOT NULL AUTO_INCREMENT,
  `domain` VARCHAR(256) NOT NULL,
  `ctime` INT(11) UNSIGNED ,
  `key` TEXT NOT NULL,
  `key_hash` varchar(512) GENERATED ALWAYS AS (sha2(`key`,224)) VIRTUAL,
  `prev_hash` varchar(512) DEFAULT NULL,
  `hash` varchar(512) GENERATED ALWAYS AS (sha2(concat(`id`,`domain`,`key`,`prev_hash`),512)) VIRTUAL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `key_hash` (`key_hash`),
  UNIQUE KEY `prev_hash` (`prev_hash`)
) ENGINE=InnoDB DEFAULT CHARSET=ascii COLLATE=ascii_general_ci;