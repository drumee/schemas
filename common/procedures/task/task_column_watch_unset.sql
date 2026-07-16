-- Unsubscribe a user from a column's change-notifications.
DELIMITER $
DROP PROCEDURE IF EXISTS `task_column_watch_unset`$
CREATE PROCEDURE `task_column_watch_unset`(
  IN _uid VARCHAR(16),
  IN _nid VARCHAR(16),
  IN _column_key VARCHAR(32)
)
BEGIN
  DELETE FROM task_column_watch
   WHERE uid = _uid
     AND nid = IFNULL(NULLIF(_nid, ''), '0')
     AND column_key = _column_key;
END$
DELIMITER ;
