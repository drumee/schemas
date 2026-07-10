-- Drumate channel-schema parity for per-file chat threads.
-- Brings drumate (personal-workspace) DBs up to the same channel schema hub
-- DBs already have, so the now-shared common/procedures/channel/* SPs run in
-- drumate context too. Fixes: ER_SP_DOES_NOT_EXIST on channel_file_thread_* in
-- personal workspaces (server calls them on this.db = the caller's drumate DB).
--
-- Fully idempotent. Apply once per drumate DB:
--   bin/patch-from-file drumate/patches/2026-07-10-channel-drumate-parity.sql drumate
--
-- Objects added (all already present in hub DBs; missing only in older drumate DBs):
--   1) channel.mention_ids column                                    (mentions feature)
--   2) channel.file_thread_id column + channel_file_thread_idx index  (file-thread feature)
--   3) file_thread table                                             (file-thread feature — Aaron)
--   4) delete_channel table   (per-user "delete for me" chat — referenced by channel_list_messages
--                              / channel_file_thread_list_messages; owned by Vu Dang's chat work)
--   5) map_ticket table       (message↔ticket map — referenced by channel_post_message)
-- The shared common/procedures/channel/* SPs reference exactly these hub-only channel columns
-- (mention_ids, file_thread_id) plus these tables; drumate's other channel columns already match hub.
-- NOTE: (4)/(5) are pulled in as hard dependencies of the shared channel SPs, not by the
--       file-thread feature itself — confirm with the respective owners before prod rollout.

-- ---- 1) channel.mention_ids column ----------------------------------------
SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'channel'
    AND COLUMN_NAME  = 'mention_ids'
);
SET @sql = IF(
  @col_exists = 0,
  'ALTER TABLE `channel` ADD COLUMN `mention_ids` JSON NULL',
  'SELECT "channel.mention_ids already exists — skipped" AS info'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

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

-- ---- channel_file_thread_idx index ----------------------------------------
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

-- ---- 2) file_thread table --------------------------------------------------
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

-- ---- 3) delete_channel table (dep of channel_list_messages / *_list_messages) --
CREATE TABLE IF NOT EXISTS `delete_channel` (
  `uid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `ref_sys_id` int(11) unsigned NOT NULL,
  `ctime` int(11) NOT NULL,
  UNIQUE KEY `id` (`uid`,`ref_sys_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- ---- 4) map_ticket table (dep of channel_post_message) ---------------------
CREATE TABLE IF NOT EXISTS `map_ticket` (
  `sys_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `message_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `ticket_id` int(11) unsigned NOT NULL,
  PRIMARY KEY (`sys_id`),
  UNIQUE KEY `id` (`message_id`,`ticket_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
