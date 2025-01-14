DROP TABLE IF EXISTS `readlog`;
CREATE TABLE `readlog` (
  `uid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `hub_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `pid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `nid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `ctime` int(11) DEFAULT NULL,
  `unread` int(11) DEFAULT 1,
  PRIMARY KEY  `pkey` (`uid`,`hub_id`,`nid`)
) 