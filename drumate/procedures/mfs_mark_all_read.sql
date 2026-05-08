-- File: schemas/drumate/procedures/mfs_mark_all_read.sql
-- Purpose: Mark all notifications as read by updating last_read_id

DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_mark_all_read`$

CREATE PROCEDURE `mfs_mark_all_read`(
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

  -- Dismiss every undismissed contact_activity row addressed to this user
  -- (hub invitations, contact invitations, etc). Keeps the underlying event
  -- around for audit but hides it from the activity feed.
  UPDATE yp.contact_activity
     SET dismissed_at = _mtime
   WHERE target_uid = _user_id
     AND dismissed_at IS NULL;

  -- Advance every p2p chat read pointer to the latest seen ctime per peer,
  -- so notification_center stops counting these as unread.
  INSERT INTO p2p_read (uid, peer_id, ref_ctime)
  SELECT _user_id, pt.peer_id, pt.ref_ctime
    FROM p2p_time pt
  ON DUPLICATE KEY UPDATE
    ref_ctime = VALUES(ref_ctime);

  SELECT
    user_id,
    last_read_id,
    mtime,
    'ok' AS status
  FROM mfs_ack
  WHERE user_id = _user_id;

END$

DELIMITER ;