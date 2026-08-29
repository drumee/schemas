-- Transitive parent/descendant relation for the scoped MFS name projection.
-- A self row has depth 0.  The supported edge depth is 1,001; maintenance
-- rejects a deeper tree instead of silently truncating the relation.

CREATE TABLE IF NOT EXISTS `mfs_search_closure` (
  `ancestor_nid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `descendant_nid` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `depth` smallint(5) unsigned NOT NULL,
  `generation` bigint(20) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`ancestor_nid`,`descendant_nid`),
  KEY `mfs_search_closure_descendant_idx` (`descendant_nid`,`depth`,`ancestor_nid`),
  KEY `mfs_search_closure_ancestor_depth_idx` (`ancestor_nid`,`depth`,`descendant_nid`),
  KEY `mfs_search_closure_generation_idx` (`generation`,`ancestor_nid`,`descendant_nid`),
  CONSTRAINT `mfs_search_closure_depth_chk` CHECK (`depth` <= 1001)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin
COMMENT='Current media parent closure for scoped name search';
