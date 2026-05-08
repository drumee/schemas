DELIMITER $

DROP PROCEDURE IF EXISTS `file_version_get`$
CREATE PROCEDURE `file_version_get`(
  IN _nid VARCHAR(16)
)
BEGIN
  -- Result set 1: file base info
  SELECT
    m.id AS nid,
    m.user_filename AS filename,
    m.filesize,
    m.extension AS ext,
    m.category,
    m.mimetype,
    m.file_path,
    m.upload_time AS ctime,
    m.publish_time AS mtime
  FROM media m
  WHERE m.id = _nid;

  -- Result set 2: version history newest first
  SELECT
    fv.id,
    fv.nid,
    fv.version_num,
    fv.filename,
    fv.filesize,
    fv.file_path,
    fv.created_by,
    fv.ctime,
    fv.is_active,
    CONCAT(d.firstname, ' ', d.lastname) AS editor_name
  FROM file_version fv
  LEFT JOIN yp.drumate d ON d.id = fv.created_by
  WHERE fv.nid = _nid
  ORDER BY fv.version_num DESC;
END$

DELIMITER ;