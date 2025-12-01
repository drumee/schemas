-- File: schemas/drumate/procedures/mfs_acknowledge_file.sql
-- Purpose: Mark a specific file/folder as seen by recording in mfs_ack table
-- This replaces the old mfs_mark_as_seen which used JSON metadata

DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_acknowledge_file`$

CREATE PROCEDURE `mfs_acknowledge_file`(
  IN _user_id VARCHAR(16),
  IN _node_id VARCHAR(16)
)
BEGIN
  DECLARE _changelog_id INT(11) UNSIGNED DEFAULT 0;
  DECLARE _mtime INT(11) UNSIGNED;
  
  SELECT UNIX_TIMESTAMP() INTO _mtime;
  
  SELECT MAX(id) INTO _changelog_id
  FROM yp.mfs_changelog
  WHERE JSON_VALUE(src, '$.nid') = _node_id
     OR JSON_VALUE(dest, '$.nid') = _node_id;
  
  IF _changelog_id IS NULL OR _changelog_id = 0 THEN
    SELECT IFNULL(MAX(id), 0) INTO _changelog_id
    FROM yp.mfs_changelog;
  END IF;
  
  -- Update or insert acknowledgement
  -- This will mark all events up to _changelog_id as read
  INSERT INTO mfs_ack (user_id, last_read_id, mtime)
  VALUES (_user_id, _changelog_id, _mtime)
  ON DUPLICATE KEY UPDATE
    last_read_id = IF(_changelog_id > last_read_id, _changelog_id, last_read_id),
    mtime = _mtime;
  
  SELECT 
    user_id,
    last_read_id,
    mtime,
    'ok' AS status
  FROM mfs_ack
  WHERE user_id = _user_id;
  
END$

DELIMITER ;