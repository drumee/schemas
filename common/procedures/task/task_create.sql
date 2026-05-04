DELIMITER $
DROP PROCEDURE IF EXISTS `task_create`$
CREATE PROCEDURE `task_create`(
  IN _id VARCHAR(16),
  IN _title VARCHAR(500),
  IN _description TEXT,
  IN _status VARCHAR(20),
  IN _priority VARCHAR(20),
  IN _due_date DATE,
  IN _created_by VARCHAR(16),
  IN _assignee_uid VARCHAR(16)
)
BEGIN
  DECLARE _rank INT DEFAULT 0;
  DECLARE _now INT DEFAULT UNIX_TIMESTAMP();

  -- rank = max rank in same status column + 1 (places task at the bottom)
  SELECT IFNULL(MAX(rank), 0) + 1
    INTO _rank
    FROM task
   WHERE status = _status;

  INSERT INTO task (
    id, title, description, status, priority, due_date,
    created_by, assignee_uid, rank, ctime, mtime
  )
  VALUES (
    _id, _title, _description, _status, IFNULL(_priority, 'medium'), _due_date,
    _created_by, _assignee_uid, _rank, _now, _now
  );

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
