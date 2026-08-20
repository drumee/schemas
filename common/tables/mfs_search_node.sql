-- Current-node projection for scoped MFS name search.
--
-- `media` remains the source of truth.  This table is deliberately additive:
-- maintenance procedures copy the authoritative parent/name/status/category/
-- isalink values and a reader must only use rows from a READY generation.
-- Paths are relative to the database home root (the parent_id='0' root name is
-- omitted), not to a client supplied folder.

CREATE TABLE IF NOT EXISTS `mfs_search_node` (
  `nid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `parent_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `name` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `name_fold` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `extension` varchar(100) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `mimetype` varchar(100) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT '',
  `category` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT 'other',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL DEFAULT 'active',
  `isalink` tinyint(2) unsigned NOT NULL DEFAULT 0,
  `file_path` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `mention_path` mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `mention_path_fold` mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `generation` bigint(20) unsigned NOT NULL DEFAULT 0,
  `source_mtime` int(11) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`nid`),
  KEY `mfs_search_node_parent_idx` (`parent_id`),
  KEY `mfs_search_node_name_fold_idx` (`name_fold`),
  KEY `mfs_search_node_generation_idx` (`generation`,`nid`),
  KEY `mfs_search_node_path_prefix_idx` (`mention_path`(255)),
  KEY `mfs_search_node_path_fold_prefix_idx` (`mention_path_fold`(255)),
  KEY `mfs_search_node_status_idx` (`status`,`category`,`isalink`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin
COMMENT='Current media-name/path projection; media is authoritative';
