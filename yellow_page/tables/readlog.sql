DROP TABLE IF EXISTS `readlog`;
CREATE TABLE `readlog` (
  `uid` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `type` enum('media', 'chat', 'ticket', 'channel'),
  `ctime` int(11) DEFAULT NULL,
  PRIMARY KEY `pkey` (`uid`,`type`)
);
