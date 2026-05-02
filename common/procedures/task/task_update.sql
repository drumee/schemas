DELIMITER $
DROP PROCEDURE IF EXISTS `task_update`$
CREATE PROCEDURE `task_update`(
  IN _id VARCHAR(16),
  IN _title VARCHAR(500),
  IN _description TEXT,
  IN _priority VARCHAR(20),
  IN _due_date DATE
)
BEGIN
  -- title / description / priority: NULL means "keep existing value"
  -- due_date: passed through directly (NULL clears the date)
  UPDATE task
     SET title       = IFNULL(_title, title),
         description = IFNULL(_description, description),
         priority    = IFNULL(_priority, priority),
         due_date    = _due_date,
         mtime       = UNIX_TIMESTAMP()
   WHERE id = _id;

  SELECT
    t.id, t.title, t.description, t.status, t.priority, t.due_date,
    t.created_by, t.assignee_uid, t.rank, t.ctime, t.mtime,
    GROUP_CONCAT(tl.label_id) AS label_ids
  FROM task t
  LEFT JOIN task_label tl ON tl.task_id = t.id
  WHERE t.id = _id
  GROUP BY t.id;
END$
DELIMITER ;
