-- File: schemas/yellow_page/patches/2026-08-26-feature-usage-aha-signals.sql
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
-- LIVES UNDER yellow_page/patches/, NOT THE TOP-LEVEL patches/ DIRECTORY, and
-- the difference is not cosmetic: bin/patch-from-manifest routes a manifest
-- line by its <db-class>/ prefix and has no branch for a bare `patches/` one,
-- so such a line resolves to target=null and is SKIPPED in silence.
-- bin/patch-from-file rejects it outright (patch.js `_types`). The three
-- cross-database backfills at the top level are hand-applied and are not in
-- the manifest, so the gap costs them nothing; a schema change that must
-- reach every install through normal tooling cannot live there.
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
