-- Failure-isolation + audit log for channel_migrate_moved_scope (cross-hub
-- folder move chat migration). One row per notable event: schema probe
-- no-op, SQLEXCEPTION absorbed by the helper's CONTINUE handler, id
-- collision remap, F9 root-card re-scope, or capture-then-delete summary.
-- Never read by product code paths — diagnostics only. Lives in the
-- DESTINATION hub/drumate db (the helper's own schema), one log row set
-- per migrated node subtree.
CREATE TABLE IF NOT EXISTS `channel_migrate_log` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `src_hub_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `dest_hub_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `uid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `old_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `new_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `stage` varchar(50) NOT NULL,
  `detail` text DEFAULT NULL,
  `ctime` int(11) unsigned NOT NULL,
  PRIMARY KEY (`sys_id`),
  KEY `channel_migrate_log_stage_idx` (`stage`, `ctime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
