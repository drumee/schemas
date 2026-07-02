DELIMITER $

DROP PROCEDURE IF EXISTS `file_version_purge_expired`$
CREATE PROCEDURE `file_version_purge_expired`(
  IN _days INT
)
BEGIN
  -- Enforce the org retention window: drop OLD (is_active=0) file versions whose
  -- ctime is older than _days. The active version (is_active=1) is never touched.
  -- DB-only, matching the existing file_version_delete_old admin action (on-disk
  -- version blobs are reclaimed by the node-level mfs_purge / remove_node path).
  DECLARE _cutoff INT DEFAULT 0;
  SET _cutoff = UNIX_TIMESTAMP() - (_days * 86400);

  DELETE FROM file_version
  WHERE is_active = 0 AND ctime < _cutoff;

  SELECT ROW_COUNT() AS purged;
END$

DELIMITER ;
