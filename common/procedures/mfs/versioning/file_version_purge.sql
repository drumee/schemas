DELIMITER $

-- ==============================================================
-- Hard-delete every file_version row for the given nid. Called
-- from mfs_purge so version metadata never outlives the media
-- row it points to. The on-disk version blobs live under
-- mfs_root/{nid}/versions/ and are removed by the existing
-- remove_node() rm -rf when the node directory is wiped.
-- ==============================================================

DROP PROCEDURE IF EXISTS `file_version_purge`$
CREATE PROCEDURE `file_version_purge`(
  IN _nid VARCHAR(16)
)
BEGIN
  DELETE FROM file_version WHERE nid = _nid;
END$

DELIMITER ;
