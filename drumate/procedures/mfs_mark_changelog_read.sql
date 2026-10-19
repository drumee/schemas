-- File: schemas/drumate/procedures/mfs_mark_changelog_read.sql
-- Purpose: Mark the file notifications (yp.mfs_changelog) as read, and nothing
-- else. mfs_mark_all_read also marks every contact_activity row read and
-- advances every p2p chat pointer, so it cannot serve a "mark this tab read"
-- that is scoped to Files: clearing Files through it cleared the Task,
-- Meeting, Other and Chat tabs too.

DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_mark_changelog_read`$

CREATE PROCEDURE `mfs_mark_changelog_read`(
  IN _user_id VARCHAR(16),
  IN _last_id INT(11) UNSIGNED
)
BEGIN
  DECLARE _mtime INT(11) UNSIGNED;
  DECLARE _max_id INT(11) UNSIGNED;

  SELECT UNIX_TIMESTAMP() INTO _mtime;

  -- If _last_id is 0 or NULL, get max from user's changelog
  IF _last_id IS NULL OR _last_id = 0 THEN
    SELECT IFNULL(MAX(id), 0) INTO _max_id FROM yp.mfs_changelog;
    SET _last_id = _max_id;
  END IF;

  INSERT INTO mfs_ack (user_id, last_read_id, mtime)
  VALUES (_user_id, _last_id, _mtime)
  ON DUPLICATE KEY UPDATE
    last_read_id = _last_id,
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
