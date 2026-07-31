-- Resolve the uids subscribed to a given column of a given folder. The server
-- uses this to fan a task-change notification out to that column's watchers.
DELIMITER $
DROP PROCEDURE IF EXISTS `task_column_watchers`$
CREATE PROCEDURE `task_column_watchers`(
  IN _nid VARCHAR(16),
  IN _column_key VARCHAR(32)
)
BEGIN
  SELECT w.uid
    FROM task_column_watch w
    INNER JOIN permission p
      ON p.entity_id = w.uid
     AND p.resource_id = '*'
     AND p.permission > 0
     AND (p.expiry_time = 0 OR p.expiry_time > UNIX_TIMESTAMP())
   WHERE w.nid = IFNULL(NULLIF(_nid, ''), '0')
     AND w.column_key = _column_key;
END$
DELIMITER ;
