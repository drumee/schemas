-- Add is_done flag to task_column (idempotent). A column with is_done = 1 is a
-- "completed" column: tasks in it are treated as done, which drives
-- completed_at stamping and the Project Health completed/overdue stats. This
-- replaces the previous hardcoded reliance on the literal status key 'complete',
-- so the four built-in columns can now be renamed / recoloured / reordered /
-- deleted like any custom column without breaking completion tracking.
SET @c := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME  = 'task_column'
     AND COLUMN_NAME = 'is_done'
);
SET @s := IF(
  @c = 0,
  'ALTER TABLE task_column ADD COLUMN is_done TINYINT(1) NOT NULL DEFAULT 0 AFTER position',
  'DO 0'
);
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- Backfill: an already-seeded built-in 'complete' column (from before this flag
-- existed) must become the done column so existing boards keep working.
UPDATE task_column SET is_done = 1 WHERE id = 'complete' AND is_done = 0;
