DELIMITER $

DROP PROCEDURE IF EXISTS `file_version_delete_old`$
CREATE PROCEDURE `file_version_delete_old`(
  IN _nid VARCHAR(16)
  -- NULL = delete old versions for ALL files in hub
)
BEGIN
  DELETE FROM file_version
  WHERE is_active = 0
    AND (_nid IS NULL OR _nid = '' OR nid = _nid);

  SELECT ROW_COUNT() AS deleted;
END$

DELIMITER ;