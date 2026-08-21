-- ALTER TABLE migration — existing hub / drumate databases
-- Adds `reporter_uid` to `task` for the editable Reporter field, and extends
-- `task_activity.action` with a 'reporter' value so a reporter change lands in
-- the folder's activity feed like an assignee change does.
--
-- WHY A SECOND COLUMN, not a mutable `created_by`: created_by is provenance.
-- The task detail panel renders the creation timestamp (task.ctime) right beside
-- the reporter, so "created on <date>" would start lying the moment a reporter
-- was reassigned, and the real creator would be gone for good. reporter_uid is
-- the editable field; created_by stays write-once (task_create only) and keeps
-- being the answer to "who actually opened this task".
--
-- Existing rows are backfilled to created_by, which is exactly what the UI was
-- already displaying — so the migration is invisible to users. NULL is treated
-- as "same as created_by" everywhere anyway (see the COALESCE in the task SPs),
-- so a database that has NOT been patched keeps rendering the creator and the
-- feature simply degrades to read-only. Safe to run multiple times.
--
-- Apply to every common-class DB individually, e.g.:
--   bin/patch-from-file common/patches/alter_task_add_reporter.sql common

-- ---------------------------------------------------------------------------
-- task.reporter_uid
-- ---------------------------------------------------------------------------
-- Guarded on the TABLE as well as the column: information_schema.COLUMNS
-- returns 0 both when the column is missing AND when the table itself is
-- missing, and patch.js treats ER_NO_SUCH_TABLE (1146) as fatal for the whole
-- fleet run — many installs never provisioned the tasks feature at all.
SET @has_tbl := (
  SELECT COUNT(*) FROM information_schema.TABLES
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'task'
);

SET @col_exists = (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'task'
    AND COLUMN_NAME  = 'reporter_uid'
);

-- CHARACTER SET ascii is NOT optional: it must match created_by / assignee_uid
-- (ascii_general_ci). A utf8mb4 column here makes every join and COALESCE
-- against them raise ER_CANT_AGGREGATE_2COLLATIONS (1267) — the same trap
-- documented in task_update_status and alter_task_add_parent.
SET @sql = IF(
  @has_tbl = 1 AND @col_exists = 0,
  'ALTER TABLE `task` ADD COLUMN `reporter_uid` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL AFTER `created_by`',
  'SELECT "task.reporter_uid column already exists — skipped" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- Backfill: every pre-existing task reported by its creator
-- ---------------------------------------------------------------------------
-- Only touches rows still NULL, so re-running is a no-op. The SPs COALESCE
-- anyway, but backfilling means idx_reporter_uid below is actually usable for a
-- future "reported by me" filter instead of indexing a column of NULLs.
SET @sql = IF(
  @has_tbl = 1,
  'UPDATE `task` SET `reporter_uid` = `created_by` WHERE `reporter_uid` IS NULL',
  'SELECT "no task table — skipped" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- task.idx_reporter_uid
-- ---------------------------------------------------------------------------
SET @idx_exists = (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'task'
    AND INDEX_NAME   = 'idx_reporter_uid'
);

SET @sql = IF(
  @has_tbl = 1 AND @idx_exists = 0,
  'ALTER TABLE `task` ADD KEY `idx_reporter_uid` (`reporter_uid`)',
  'SELECT "task.idx_reporter_uid already exists — skipped" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- task_activity.action += 'reporter'
-- ---------------------------------------------------------------------------
-- An ENUM rejects an unlisted value outright (STRICT_TRANS_TABLES) — without
-- this, task_activity_log('reporter') would fail and, because logging is
-- best-effort, the reporter change would silently never appear in the feed.
-- MODIFY is safe to re-run: it restates the full value list either way, so the
-- guard below only avoids a needless table rebuild.
SET @act_tbl := (
  SELECT COUNT(*) FROM information_schema.TABLES
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'task_activity'
);

SET @has_val := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'task_activity'
    AND COLUMN_NAME  = 'action'
    AND COLUMN_TYPE LIKE '%''reporter''%'
);

SET @sql = IF(
  @act_tbl = 1 AND @has_val = 0,
  'ALTER TABLE `task_activity` MODIFY COLUMN `action` ENUM(''create'',''update'',''status'',''assignee'',''reporter'',''link_file'',''comment'',''complete'') NOT NULL',
  'SELECT "task_activity.action already accepts reporter — skipped" AS info'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
