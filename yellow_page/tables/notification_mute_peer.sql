CREATE TABLE IF NOT EXISTS `notification_mute_peer` (
  `uid` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL
    COMMENT 'Reference to yp.drumate.id -- the user who muted',
  `peer_id` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL
    COMMENT 'Reference to yp.drumate.id -- the person whose DM popups are muted',
  `ctime` int(11) unsigned NOT NULL
    COMMENT 'When muted. Preserved when the same person is muted again.',
  PRIMARY KEY (`uid`,`peer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Direct-message popup mute per person -- popup channel only, never the feed or the badge';
