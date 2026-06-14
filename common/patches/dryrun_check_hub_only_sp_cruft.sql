-- DRY-RUN / VERIFICATION ONLY — read-only, makes no changes.
--
-- Run this BEFORE applying cleanup_hub_only_sp_cruft.sql to preview exactly
-- which non-hub-shaped DBs currently carry stale copies of
-- hub_get_members_by_type and/or add_member, and confirm the count matches
-- expectations before the actual DROP runs. Uses the same "has the `article`
-- table" structural test as the cleanup patch.
--
-- Why structural, not metadata-based: an earlier draft used "has a yp.hub
-- row" to mean "is a genuine hub". That's wrong — pre-provisioned hub-pool
-- instances (factory-seeded from hub.sql, sitting in area='pool' awaiting
-- assignment) are genuinely hub-shaped but have no yp.hub row yet, so that
-- test would have flagged ~2,250 legitimate instances as cruft. The `article`
-- table exists in all 3,234 genuine hub DBs (verified) and zero sampled
-- personal/drumate DBs, including pool ones — a reliable shape test that
-- doesn't depend on assignment timing.
--
-- Uses mysql.proc directly (fast, single-table scan) rather than
-- information_schema.ROUTINES, which times out / returns incomplete results
-- at this server's scale.
--
-- Run from any connection with access to mysql.proc + information_schema + yp:
--   mariadb -N -e "source dryrun_check_hub_only_sp_cruft.sql"

SELECT
  r.name AS routine_name,
  COUNT(DISTINCT r.db) AS stale_db_count
FROM mysql.proc r
INNER JOIN yp.entity e ON e.db_name = r.db
LEFT JOIN information_schema.TABLES t ON t.TABLE_SCHEMA = r.db AND t.TABLE_NAME = 'article'
WHERE r.name IN ('hub_get_members_by_type', 'add_member')
  AND r.type = 'PROCEDURE'
  AND t.TABLE_NAME IS NULL              -- not hub-shaped
GROUP BY r.name
ORDER BY stale_db_count DESC;
