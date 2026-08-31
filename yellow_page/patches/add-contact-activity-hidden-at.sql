-- Separate read acknowledgement (dismissed_at, retained for compatibility)
-- from explicit removal out of full Activity history (hidden_at).
-- Rows already dismissed at first rollout keep the legacy hidden behavior;
-- rows acknowledged after rollout remain visible in full history.

SET @contact_hidden_at_existed := (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'contact_activity'
    AND column_name = 'hidden_at'
);

ALTER TABLE contact_activity
  ADD COLUMN IF NOT EXISTS hidden_at INT(11) UNSIGNED DEFAULT NULL
    COMMENT 'When the recipient removed this row from Activity history'
    AFTER dismissed_at,
  ALGORITHM=INPLACE, LOCK=NONE;

-- Before hidden_at existed, dismissed_at was the sole hide marker (including
-- mark-all). Preserve that established behavior exactly once. Manifest replay
-- must never hide rows that were merely marked read after this migration.
SET @contact_hidden_at_backfill_sql := IF(
  @contact_hidden_at_existed = 0,
  'UPDATE contact_activity SET hidden_at = dismissed_at WHERE dismissed_at IS NOT NULL AND hidden_at IS NULL',
  'DO 0'
);
PREPARE contact_hidden_at_backfill_stmt FROM @contact_hidden_at_backfill_sql;
EXECUTE contact_hidden_at_backfill_stmt;
DEALLOCATE PREPARE contact_hidden_at_backfill_stmt;

ALTER TABLE contact_activity
  ADD INDEX IF NOT EXISTS idx_target_hidden_time
    (`target_uid`, `hidden_at`, `timestamp`, `id`),
  ALGORITHM=INPLACE, LOCK=NONE;
