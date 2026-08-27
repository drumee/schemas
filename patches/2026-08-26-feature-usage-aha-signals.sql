-- File: schemas/patches/2026-08-26-feature-usage-aha-signals.sql
-- Purpose: widen yp.feature_usage.feature to carry the two Aha-moment signals.
--
-- 'file_thread' -- a chat thread STARTED on a file (channel.file_thread_post
--                  with is_new). Backfillable: every hub database has a
--                  `file_thread` table. See patches/aha_usage_backfill.sql.
-- 'gdrive'      -- a completed Google Drive migration, volume = bytes moved.
--                  NOT backfillable: job state lives in Bull/Redis.
--
-- IDEMPOTENT. MODIFY COLUMN restates the whole definition, so re-applying it
-- is a no-op rather than an error -- which is what lets this file sit in
-- manifest.txt safely, unlike aha_usage_backfill.sql next door.
--
-- APPLY THIS BEFORE PATCHING feature_mark, and both before deploying
-- server-team. feature_mark SIGNALs on an unknown feature (deliberately, so a
-- typo surfaces instead of under-counting silently), so a server marking
-- 'file_thread' against the old proc raises on every thread creation. In this
-- order each step is safe on its own.

ALTER TABLE `feature_usage`
  MODIFY COLUMN `feature`
    enum('upload','chat','task','meeting','file_thread','gdrive') NOT NULL
    COMMENT 'Which tracked feature this row records';

ALTER TABLE `feature_usage`
  MODIFY COLUMN `volume` bigint(20) unsigned NOT NULL DEFAULT 0
    COMMENT 'Cumulative bytes: uploaded (upload) or migrated (gdrive). 0 elsewhere.';
