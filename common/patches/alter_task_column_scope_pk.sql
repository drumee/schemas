-- ALTER TABLE migration — existing hub / drumate databases
-- Make task_column's identity FOLDER-SCOPED: PRIMARY KEY (id, nid).
--
-- Why: task_column_list seeds the four built-in columns as real rows per folder
-- scope, using their canonical status keys as ids ('todo', 'in_progress',
-- 'to_review', 'complete'). Under PRIMARY KEY (id) those ids can exist only
-- ONCE PER DATABASE, so only the first scope whose board is opened gets them —
-- every other scope's INSERT IGNORE hits the key collision, stores nothing, yet
-- still records its task_column_init marker and is therefore never seeded
-- again. Boards in those scopes render their custom columns alone and silently
-- hide every task whose status is a built-in key.
--
-- nid must become NOT NULL first: a PRIMARY KEY column cannot hold NULL, and
-- the workspace-root scope has historically been stored as NULL. '' is already
-- the canonical root marker elsewhere (task_column_init.scope_key uses
-- IFNULL(_nid, '')), so root collapses to '' here too. The task_column procs
-- normalise _nid to '' so `nid <=> _nid` keeps matching root-scope calls.
--
-- (id, nid) is a superset of the existing unique (id), so the new key can never
-- collide on existing rows. Every step is guarded and safe to run repeatedly.
--
-- ⚠️ Ships in LOCKSTEP with the task_column procs (task_column_get/update/
-- delete gain an _nid parameter) and their server + UI call sites. Applying
-- this migration alone leaves delete/update keyed on id only, which under a
-- composite key would hit EVERY scope's copy of a built-in.
--
-- Apply to every common-class DB individually, e.g.:
--   bin/patch-from-file common/patches/alter_task_column_scope_pk.sql common

SET @has_tc := (
  SELECT COUNT(*) FROM information_schema.TABLES
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'task_column'
);

-- ---------------------------------------------------------------------------
-- 1. Collapse the historical NULL root scope onto ''
-- ---------------------------------------------------------------------------
SET @sql := IF(
  @has_tc = 1,
  'UPDATE `task_column` SET `nid` = '''' WHERE `nid` IS NULL',
  'DO 0'
);
PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;

-- ---------------------------------------------------------------------------
-- 2. nid NOT NULL (no-op when already applied)
-- ---------------------------------------------------------------------------
SET @nullable := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'task_column'
     AND COLUMN_NAME  = 'nid'
     AND IS_NULLABLE  = 'YES'
);
SET @sql := IF(
  @has_tc = 1 AND @nullable = 1,
  'ALTER TABLE `task_column` MODIFY `nid` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT ''''',
  'DO 0'
);
PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;

-- ---------------------------------------------------------------------------
-- 3. PRIMARY KEY (id) -> (id, nid)
--    Guarded on the current key column count, so a re-run is a no-op.
-- ---------------------------------------------------------------------------
SET @pk_cols := (
  SELECT COUNT(*) FROM information_schema.STATISTICS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME   = 'task_column'
     AND INDEX_NAME   = 'PRIMARY'
);
SET @sql := IF(
  @has_tc = 1 AND @pk_cols = 1,
  'ALTER TABLE `task_column` DROP PRIMARY KEY, ADD PRIMARY KEY (`id`, `nid`)',
  'DO 0'
);
PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;

-- ---------------------------------------------------------------------------
-- 4. Purge the poisoned init markers.
--    A scope marked "seeded" that holds NO built-in row was a swallowed
--    INSERT IGNORE; clearing the marker lets task_column_list seed it properly
--    on the next open, now that the composite key permits it.
--
--    ⚠️ KNOWN AMBIGUITY: a scope where the user genuinely DELETED all four
--    built-ins is indistinguishable from a poisoned one — no timestamp or flag
--    separates them — so such a board would be re-seeded on next open. That is
--    the same state a fresh board starts in, and is strictly preferable to
--    permanently hidden tasks. Scopes retaining even ONE built-in are left
--    untouched, so ordinary single-column deletes still persist.
-- ---------------------------------------------------------------------------
SET @has_init := (
  SELECT COUNT(*) FROM information_schema.TABLES
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'task_column_init'
);
SET @sql := IF(
  @has_tc = 1 AND @has_init = 1,
  'DELETE i FROM `task_column_init` i
    WHERE NOT EXISTS (
      SELECT 1 FROM `task_column` c
       WHERE c.`nid` = i.`scope_key`
         AND c.`id` IN (''todo'', ''in_progress'', ''to_review'', ''complete'')
    )',
  'DO 0'
);
PREPARE st FROM @sql; EXECUTE st; DEALLOCATE PREPARE st;
