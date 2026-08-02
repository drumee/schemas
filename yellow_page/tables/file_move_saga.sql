CREATE TABLE IF NOT EXISTS `file_move_saga` (
  `operation_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `lineage_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `actor_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `source_hub_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `source_file_nid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `source_parent_nid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `source_thread_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `destination_hub_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `destination_parent_nid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `destination_file_nid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `destination_thread_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `compensation_file_nid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `compensation_thread_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `source_access_revision` bigint(20) unsigned NOT NULL,
  `access_revision` bigint(20) unsigned DEFAULT NULL,
  `state` enum(
    'copy_pending','copy_verified','source_removed','committed',
    'compensating','compensated','failed','expired','compensation_failed'
  ) NOT NULL DEFAULT 'copy_pending',
  `failure_code` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `retry_count` int(11) unsigned NOT NULL DEFAULT 0,
  `expires_at` int(11) unsigned NOT NULL,
  `ctime` int(11) unsigned NOT NULL,
  `mtime` int(11) unsigned NOT NULL,
  `committed_at` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`operation_id`),
  UNIQUE KEY `file_move_saga_replay_uidx` (
    `lineage_id`,`source_hub_id`,`source_file_nid`,
    `destination_hub_id`,`destination_parent_nid`
  ),
  KEY `file_move_saga_lineage_idx` (`lineage_id`,`ctime`),
  KEY `file_move_saga_expiry_idx` (`state`,`expires_at`),
  KEY `file_move_saga_destination_idx` (`destination_hub_id`,`destination_file_nid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
  COMMENT='Durable server-only state machine for a single-destination cross-hub file move';
