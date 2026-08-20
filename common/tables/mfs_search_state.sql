-- One-row readiness/epoch state for the additive search projection.
-- Readers must require state=READY and use the same generation on both
-- projection tables.  BUILDING/FAILED/DISABLED are fail-closed states.

CREATE TABLE IF NOT EXISTS `mfs_search_state` (
  `state_id` tinyint(3) unsigned NOT NULL DEFAULT 1,
  `state` enum('BUILDING','READY','FAILED','DISABLED') NOT NULL DEFAULT 'BUILDING',
  `schema_version` bigint(20) unsigned NOT NULL DEFAULT 1 COMMENT 'DDL contract version',
  `projection_version` bigint(20) unsigned NOT NULL DEFAULT 1 COMMENT 'Reader/maintenance contract version',
  `generation` bigint(20) unsigned NOT NULL DEFAULT 0 COMMENT 'Atomically published data epoch',
  `mutation_high_water` bigint(20) unsigned NOT NULL DEFAULT 0 COMMENT 'Committed media mutations observed by maintenance triggers',
  `reconciled_high_water` bigint(20) unsigned NOT NULL DEFAULT 0 COMMENT 'Last mutation high-water included in the published projection',
  `row_count` bigint(20) unsigned NOT NULL DEFAULT 0,
  `last_error_code` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `last_error_message` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `started_at` int(11) unsigned DEFAULT NULL,
  `finished_at` int(11) unsigned DEFAULT NULL,
  `updated_at` int(11) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`state_id`),
  CONSTRAINT `mfs_search_state_singleton_chk` CHECK (`state_id` = 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin
COMMENT='Readiness and generation marker for mfs_search_node/closure';
