-- Part 1 of extending per-file chat threads to drumate (personal workspaces).
-- Adds ONLY what the 7 shared common/procedures/channel/channel_file_thread_* SPs
-- reference but drumate DBs lack. Purely additive — does NOT touch drumate's own
-- channel_list_messages/post/read (those get the file_thread_id delta separately
-- in Part 2, adapted to drumate's per-entity read model).
--
-- Fixes: ER_SP_DOES_NOT_EXIST on channel_file_thread_* in personal workspaces
-- (server calls them on this.db = the caller's drumate DB).
--
-- Dependency set of the 7 file-thread SPs (verified): channel, file_thread, media,
-- yp.*, pageToLimits, delete_channel, permission, channel.mention_ids/file_thread_id.
-- (map_ticket is NOT needed here — it belongs to channel_post_message, a Part-2 SP.)
--
-- Fully idempotent. Apply once per drumate DB:
--   bin/patch-from-file drumate/patches/2026-07-10-file-thread-drumate.sql drumate

-- ---- channel.mention_ids column (referenced by list_messages / ensure_root) --
SET @c = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='channel' AND COLUMN_NAME='mention_ids');
SET @sql = IF(@c=0,
  'ALTER TABLE `channel` ADD COLUMN `mention_ids` JSON NULL',
  'SELECT "channel.mention_ids exists — skipped" AS info');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ---- channel.file_thread_id column ----------------------------------------
SET @c = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='channel' AND COLUMN_NAME='file_thread_id');
SET @sql = IF(@c=0,
  'ALTER TABLE `channel` ADD COLUMN `file_thread_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL AFTER `thread_id`',
  'SELECT "channel.file_thread_id exists — skipped" AS info');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ---- channel_file_thread_idx index ----------------------------------------
SET @c = (SELECT COUNT(*) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='channel' AND INDEX_NAME='channel_file_thread_idx');
SET @sql = IF(@c=0,
  'ALTER TABLE `channel` ADD KEY `channel_file_thread_idx` (`file_thread_id`, `sys_id`)',
  'SELECT "channel_file_thread_idx exists — skipped" AS info');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ---- file_thread table -----------------------------------------------------
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

-- ---- delete_channel table (dep of channel_file_thread_list_messages) -------
CREATE TABLE IF NOT EXISTS `delete_channel` (
  `uid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `ref_sys_id` int(11) unsigned NOT NULL,
  `ctime` int(11) NOT NULL,
  UNIQUE KEY `id` (`uid`,`ref_sys_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
