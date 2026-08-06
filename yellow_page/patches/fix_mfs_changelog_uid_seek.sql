-- Make yp.mfs_changelog per-user lookups index-seekable: add idx_uid_event and
-- convert uid to utf8mb4. drumate.id is utf8mb4 on live installs, and comparing
-- ascii = utf8mb4 converts the indexed side per row, so an ascii uid can never
-- seek — analytics referral_activation full-scanned the table per user (~100s).
-- Idempotent; MODIFY rebuilds the table (ALGORITHM=COPY, a few seconds).
-- Applied by hand to prod + stage yp on 2026-08-06 (~100s -> ~40ms).

ALTER TABLE mfs_changelog
  MODIFY `uid` VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL;

ALTER TABLE mfs_changelog
  ADD INDEX IF NOT EXISTS idx_uid_event (`uid`, `event`);
