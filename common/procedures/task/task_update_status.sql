DELIMITER $
DROP PROCEDURE IF EXISTS `task_update_status`$
CREATE PROCEDURE `task_update_status`(
  IN _id VARCHAR(16),
  IN _status VARCHAR(20)
)
BEGIN
  DECLARE _rank INT DEFAULT 0;

  -- Place task at the bottom of destination column
  SELECT IFNULL(MAX(rank), 0) + 1
    INTO _rank
    FROM task
   WHERE status = _status
     AND id <> _id;

  UPDATE task
     SET status = _status,
         rank   = _rank,
         mtime  = UNIX_TIMESTAMP()
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
