DELIMITER $

-- ==============================================================
-- Snapshot a file's current content into file_version. Called
-- from media.save / media.replace just before the on-disk blob
-- is overwritten. The previous "active" snapshot is demoted so
-- only the most-recent past version is flagged is_active=1
-- (file_version_delete_old keeps that one).
--
-- The caller passes an empty _file_path placeholder, then
-- back-fills it with the real on-disk path once the blob has
-- been copied (the path embeds LAST_INSERT_ID()).
--
-- Returns: id (auto-increment PK) + version_num for the caller.
--
-- Naming note: parameter is `_fname`, NOT `_filename`. MariaDB's
-- parser treats `_filename` as a charset introducer (there is an
-- internal `filename` charset used by MyISAM/Aria for disk-safe
-- filename encoding) and reports a syntax error at the parameter
-- list. Same pitfall applies to `_binary`, `_utf8`, `_latin1`, etc.
-- ==============================================================

DROP PROCEDURE IF EXISTS `file_version_create`$
CREATE PROCEDURE `file_version_create`(
  IN _nid VARCHAR(16),
  IN _fname VARCHAR(255),
  IN _filesize BIGINT,
  IN _file_path VARCHAR(1000),
  IN _created_by VARCHAR(16)
)
BEGIN
  DECLARE _version_num INT;

  -- Demote any existing active snapshot for this nid
  UPDATE file_version
     SET is_active = 0
   WHERE nid = _nid AND is_active = 1;

  -- Compute next version_num under the row locks acquired above
  SELECT IFNULL(MAX(version_num), 0) + 1
    INTO _version_num
    FROM file_version
   WHERE nid = _nid;

  INSERT INTO file_version
    (nid, version_num, filename, filesize, file_path, created_by, ctime, is_active)
  VALUES
    (_nid, _version_num, _fname, _filesize, _file_path, _created_by, UNIX_TIMESTAMP(), 1);

  SELECT LAST_INSERT_ID() AS id, _version_num AS version_num;
END$

DELIMITER ;
