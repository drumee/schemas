DELIMITER $

-- =========================================================
-- mfs_show_bin
-- Kept for callers that predate the sort param (stage endpoints share one
-- DB server, so an older server build may still call this). Same rows and
-- order as mfs_show_bin_sorted(_page, 'latest').
-- =========================================================
DROP PROCEDURE IF EXISTS `mfs_show_bin`$
CREATE PROCEDURE `mfs_show_bin`(
  IN _page TINYINT(4)
)
BEGIN
  CALL mfs_show_bin_sorted(_page, 'latest');
END $

DELIMITER ;
