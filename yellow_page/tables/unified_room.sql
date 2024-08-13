
DROP TABLE `unified_room`;
CREATE TABLE `unified_room` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id` varchar(16) CHARACTER SET ascii NOT NULL,
  `uid` varchar(16) CHARACTER SET ascii NOT NULL,
  `is_mic_enabled` TINYINT default 1,
  `is_video_enabled` TINYINT default 0,
  `is_share_enabled` TINYINT default 0,
  `is_write_enabled` TINYINT default 0,
  `metadata`  JSON NOT NULL DEFAULT '{}',
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`id`,`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


ALTER TABLE `unified_room` ADD index `idx_id`(id);


ALTER TABLE `unified_room` ADD index `idx_uid`(uid);


ALTER TABLE `unified_room` modify column uid varchar(30) CHARACTER SET ascii NOT NULL;