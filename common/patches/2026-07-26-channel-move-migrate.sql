-- Chat-scope cross-hub migrate — schema for `mfs_move_all`'s failure-isolated
-- channel/file_thread migration helper. Idempotent. Class common: apply to
-- every hub AND drumate DB (both call mfs_move_all — chat.js:213).
--
-- HARD DEPENDENCY (deploy ordering, see plan.md): the file_thread DDL patches
-- (hub/patches/2026-06-26-channel-file-thread.sql,
-- drumate/patches/2026-07-10-file-thread-drumate.sql) MUST already be applied
-- to every hub + drumate DB before this patch ships the new mfs_move_all
-- procedure body (bin/patch-from-manifest ordering). This patch itself only
-- adds the log table + helper proc; it does not touch file_thread DDL.
--
-- Apply via:  bin/patch-from-file common/patches/2026-07-26-channel-move-migrate.sql common
--   or:       mariadb <db_name> < 2026-07-26-channel-move-migrate.sql

-- ---- channel_migrate_log table --------------------------------------------
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

-- The `channel_migrate_moved_scope` helper proc and the updated
-- `mfs_move_all` proc are applied separately via the standard SP file
-- patching path (bin/patch-from-file on the two procedure files) — stored
-- procedures are re-created via DROP+CREATE and are not idempotency-guarded
-- ALTER statements like the table above.
