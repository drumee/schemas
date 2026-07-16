-- Resolve the uids subscribed to a given column of a given folder. The server
-- uses this to fan a task-change notification out to that column's watchers.
DELIMITER $
DROP PROCEDURE IF EXISTS `task_column_watchers`$
CREATE PROCEDURE `task_column_watchers`(
  IN _nid VARCHAR(16),
  IN _column_key VARCHAR(32)
)
BEGIN
  SELECT uid
    FROM task_column_watch
   WHERE nid = IFNULL(NULLIF(_nid, ''), '0')
     AND column_key = _column_key;
END$
DELIMITER ;
