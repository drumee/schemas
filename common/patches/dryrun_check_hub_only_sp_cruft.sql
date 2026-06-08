-- DRY-RUN / VERIFICATION ONLY — read-only, makes no changes.
--
-- Run this BEFORE applying cleanup_hub_only_sp_cruft.sql to preview exactly
-- which non-hub DBs currently carry stale copies of hub_get_members_by_type
-- and/or add_member, and confirm the count matches expectations before the
-- actual DROP runs. Uses the same "has a yp.hub row" test as the cleanup
-- patch and as show_hubs itself.
--
-- Run from any connection with access to information_schema + yp:
--   mariadb -N -e "source dryrun_check_hub_only_sp_cruft.sql"

SELECT
  r.ROUTINE_NAME,
  e.area,
  COUNT(*) AS stale_db_count
FROM information_schema.ROUTINES r
JOIN yp.entity e ON e.db_name = r.ROUTINE_SCHEMA
LEFT JOIN yp.hub h ON h.id = e.id
WHERE r.ROUTINE_NAME IN ('hub_get_members_by_type', 'add_member')
  AND h.id IS NULL                      -- not a genuine hub
GROUP BY r.ROUTINE_NAME, e.area
ORDER BY r.ROUTINE_NAME, stale_db_count DESC;
