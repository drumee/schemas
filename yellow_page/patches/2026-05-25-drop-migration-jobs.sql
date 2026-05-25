-- ============================================================================
-- 2026-05-25 — Drop migration_jobs table (architecture changed)
--
-- The first cut of the Google Drive migration feature used a MariaDB
-- `migration_jobs` table for per-job state. The architecture was revised
-- to be Bull-only — job state now lives in Redis (`job.progress` + `job.
-- returnvalue` + Bull's own state machine). The table is no longer
-- referenced by any service or worker.
--
-- Drop is idempotent and safe: by the time this patch runs, no code
-- writes to or reads from migration_jobs.
-- ============================================================================

DROP TABLE IF EXISTS `migration_jobs`;
