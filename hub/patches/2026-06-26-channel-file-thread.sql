-- File Chat Threads — schema migration for existing hub databases.
-- Run once per hub DB (stage + production). Fully idempotent.
--
-- 1) channel.file_thread_id : membership marker for a per-file chat child message.
--    NULL = normal message (incl. the folder-visible "file.thread" root card);
--    non-NULL = child message belonging to that file thread (root_message_id).
--    thread_id stays reply-to-message; the two are intentionally separate.
-- 2) channel_file_thread_idx : paginated lookup of a thread's children.
-- 3) file_thread table : one row per file that has a chat thread.
--
-- Apply via:  bin/patch-from-file hub/patches/2026-06-26-channel-file-thread.sql hub
--   or:       mariadb <hub_db_name> < 2026-06-26-channel-file-thread.sql

-- ---- 1) channel.file_thread_id column -------------------------------------
SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'channel'
    AND COLUMN_NAME  = 'file_thread_id'
);
SET @sql = IF(
  @col_exists = 0,
  'ALTER TABLE `channel` ADD COLUMN `file_thread_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL AFTER `thread_id`',
  'SELECT "channel.file_thread_id already exists — skipped" AS info'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ---- 2) channel_file_thread_idx index -------------------------------------
SET @idx_exists = (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'channel'
    AND INDEX_NAME   = 'channel_file_thread_idx'
);
SET @sql = IF(
  @idx_exists = 0,
  'ALTER TABLE `channel` ADD KEY `channel_file_thread_idx` (`file_thread_id`, `sys_id`)',
  'SELECT "channel_file_thread_idx already exists — skipped" AS info'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ---- 3) file_thread table --------------------------------------------------
CREATE TABLE IF NOT EXISTS `file_thread` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `file_nid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `folder_nid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `root_message_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `created_by` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `last_message_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `reply_count` int(11) unsigned NOT NULL DEFAULT 0,
  `ctime` int(11) NOT NULL,
  `mtime` int(11) NOT NULL,
  `status` enum('active','deleted') NOT NULL DEFAULT 'active',
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `file_thread_file_uidx` (`file_nid`),
  UNIQUE KEY `file_thread_root_uidx` (`root_message_id`),
  KEY `file_thread_folder_idx` (`folder_nid`, `status`, `mtime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
