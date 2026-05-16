-- File: schemas/drumate/patches/verify_contact_dismissed_at.sql
-- Purpose: Verify the per-drumate `contact.dismissed_at` migration
--          (alter_contact_add_dismissed_at.sql) reached EVERY drumate database.
--
-- Why this exists: `contact` is a per-drumate table — one copy per user DB.
-- The migration must loop over every drumate DB, so it is easy to miss DBs
-- (e.g. users created between two migration runs). This script reports the
-- coverage in one read-only pass.
--
-- Run (no target DB needed — every name is fully qualified):
--   mariadb < verify_contact_dismissed_at.sql
--
-- Read-only. No writes. Safe to run at any time, including before migrating
-- (it will simply report everything as missing).
--
-- Note: `contact_activity.dismissed_at` lives in the single `yp` database;
-- verify that one trivially with:
--   SHOW COLUMNS FROM yp.contact_activity LIKE 'dismissed_at';

-- 1. Summary — total drumate DBs vs how many carry the column.
--    Healthy result: missing = 0.
SELECT
  COUNT(*)                       AS total_drumate_dbs,
  SUM(c.COLUMN_NAME IS NOT NULL) AS migrated,
  SUM(c.COLUMN_NAME IS NULL)     AS missing
FROM yp.entity e
LEFT JOIN information_schema.COLUMNS c
  ON  c.TABLE_SCHEMA = e.db_name
  AND c.TABLE_NAME   = 'contact'
  AND c.COLUMN_NAME  = 'dismissed_at'
WHERE e.type = 'drumate'
  AND e.db_name IS NOT NULL;

-- 2. The DBs still missing the column. An empty result set means the
--    migration reached every drumate DB. Any row here must be re-migrated:
--      mariadb "<db_name>" < alter_contact_add_dismissed_at.sql
--    (A row whose `contact` table does not exist at all also appears here —
--    check those manually; the DB may belong to a deleted user.)
SELECT
  e.db_name AS db_missing_dismissed_at,
  e.status  AS entity_status
FROM yp.entity e
LEFT JOIN information_schema.COLUMNS c
  ON  c.TABLE_SCHEMA = e.db_name
  AND c.TABLE_NAME   = 'contact'
  AND c.COLUMN_NAME  = 'dismissed_at'
WHERE e.type = 'drumate'
  AND e.db_name IS NOT NULL
  AND c.COLUMN_NAME IS NULL
ORDER BY e.db_name;
