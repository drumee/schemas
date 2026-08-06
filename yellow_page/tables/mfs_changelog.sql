DROP TABLE IF EXISTS `mfs_changelog`;
CREATE TABLE IF NOT EXISTS `mfs_changelog` (
  `id` INT(11) unsigned NOT NULL AUTO_INCREMENT,
  `timestamp` int(11) unsigned NOT NULL,
  -- utf8mb4 on purpose: compared against drumate.id (utf8mb4 on live installs);
  -- an ascii uid gets converted per-row there and idx_uid_event can never seek.
  `uid` VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `hub_id` VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci,
  `event` VARCHAR(100) CHARACTER SET ascii COLLATE ascii_general_ci,
  src JSON,
  dest JSON DEFAULT '{}',
  -- Node id extracted from src/dest; indexed so mfs_show_node_by's new-file
  -- detection uses idx_nid instead of full-scanning + JSON-parsing the table.
  -- VIRTUAL = computed, not stored (the index persists the values).
  `nid` VARCHAR(64) CHARACTER SET ascii AS (COALESCE(JSON_VALUE(src, '$.nid'), JSON_VALUE(dest, '$.nid'))) VIRTUAL,
  PRIMARY KEY (`id`),
  KEY `idx_nid` (`nid`, `id`),
  -- Per-user event lookups (analytics referral procs).
  KEY `idx_uid_event` (`uid`, `event`)
);

