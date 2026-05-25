DROP TABLE IF EXISTS `device`;
CREATE TABLE IF NOT EXISTS `device` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `uid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `name` varchar(128) NOT NULL,
  `fingerprint` varchar(256) NOT NULL,
  `platform` varchar(64) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'active',
  `ctime` int(11) NOT NULL DEFAULT 0,
  `mtime` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `fingerprint` (`fingerprint`),
  KEY `uid` (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci