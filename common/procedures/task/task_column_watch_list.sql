-- List the column keys a user is subscribed to within one folder, so the
-- board can render each column's bell in its on/off state.
DELIMITER $
DROP PROCEDURE IF EXISTS `task_column_watch_list`$
CREATE PROCEDURE `task_column_watch_list`(
  IN _uid VARCHAR(16),
  IN _nid VARCHAR(16)
)
BEGIN
  SELECT column_key
    FROM task_column_watch
   WHERE uid = _uid
     AND nid = IFNULL(NULLIF(_nid, ''), '0');
END$
DELIMITER ;
