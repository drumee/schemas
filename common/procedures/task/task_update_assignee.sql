DELIMITER $
DROP PROCEDURE IF EXISTS `task_update_assignee`$
CREATE PROCEDURE `task_update_assignee`(
  IN _id VARCHAR(16),
  IN _assignee_uid VARCHAR(16)
)
BEGIN
  -- _assignee_uid = NULL clears the assignment.
  UPDATE task
     SET assignee_uid = _assignee_uid,
         mtime        = UNIX_TIMESTAMP()
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
