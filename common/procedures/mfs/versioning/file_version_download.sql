DELIMITER $

DROP PROCEDURE IF EXISTS `file_version_download`$
CREATE PROCEDURE `file_version_download`(
  IN _nid VARCHAR(16)
)
BEGIN
  -- Return active version first, then old versions newest-first
  -- file_path is the physical path used to construct download URL
  SELECT
    fv.id,
    fv.version_num,
    fv.filename,
    fv.filesize,
    fv.file_path,
    fv.ctime,
    fv.is_active,
    CONCAT(d.firstname, ' ', d.lastname) AS editor_name
  FROM file_version fv
  LEFT JOIN yp.drumate d ON d.id = fv.created_by
  WHERE fv.nid = _nid
  ORDER BY fv.is_active DESC, fv.version_num DESC;
END$

DELIMITER ;