-- Add an indexed generated column to yp.mfs_changelog so mfs_show_node_by's
-- new-file detection can run as an index scan instead of full-scanning +
-- JSON-parsing the whole changelog on every listing.
--   nid = the node id from src/dest (the GROUP BY key in mfs_show_node_by).
-- VIRTUAL: no stored data (instant metadata add); the index persists the
-- computed values, so lookups/GROUP BY use idx_nid.
--
-- Two separate online ALTERs on purpose: MariaDB refuses to combine a virtual-
-- column add with an index add in one INPLACE statement. IF NOT EXISTS makes
-- this idempotent/safe to re-run.
--
-- ORDER: this migration MUST be applied BEFORE any mfs_show_node_by version that
-- references the `nid` column ships. The current SP still uses the inline
-- COALESCE(...) expression and ignores this column, so applying this alone is a
-- no-op for behaviour and safe to deploy independently.

ALTER TABLE mfs_changelog
  ADD COLUMN IF NOT EXISTS nid VARCHAR(64) CHARACTER SET ascii
    AS (COALESCE(JSON_VALUE(src, '$.nid'), JSON_VALUE(dest, '$.nid'))) VIRTUAL,
  ALGORITHM=INPLACE, LOCK=SHARED;

ALTER TABLE mfs_changelog
  ADD INDEX IF NOT EXISTS idx_nid (nid, id),
  ALGORITHM=INPLACE, LOCK=NONE;
