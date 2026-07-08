DELIMITER $
DROP PROCEDURE IF EXISTS `task_create`$
CREATE PROCEDURE `task_create`(
  IN _id VARCHAR(16),
  IN _title VARCHAR(500),
  IN _description TEXT,
  IN _status VARCHAR(20),
  IN _priority VARCHAR(20),
  IN _due_date DATE,
  IN _start_date DATE,
  IN _created_by VARCHAR(16),
  IN _nid VARCHAR(16)
)
BEGIN
  DECLARE _rank INT DEFAULT 0;
  DECLARE _now INT DEFAULT UNIX_TIMESTAMP();

  -- rank = max rank in the same (folder, status) column + 1 (bottom of column).
  -- Scoped by nid (null-safe) so each folder's columns rank independently.
  SELECT IFNULL(MAX(rank), 0) + 1
    INTO _rank
    FROM task
   WHERE status = _status
     AND nid <=> _nid;

  INSERT INTO task (
    id, title, description, status, priority, due_date, start_date,
    created_by, nid, rank, ctime, mtime
  )
  VALUES (
    _id, _title, _description, _status, IFNULL(_priority, 'medium'), _due_date, _start_date,
    _created_by, _nid, _rank, _now, _now
  );

  -- Assignees are set via task_set_assignees after create (multi-assignee).
  SELECT
    t.id, t.title, t.description, t.status, t.priority, t.due_date, t.start_date,
    t.created_by, t.nid, t.rank, t.ctime, t.mtime,
    GROUP_CONCAT(DISTINCT tl.label_id) AS label_ids,
    (SELECT GROUP_CONCAT(ta.uid) FROM task_assignee ta WHERE ta.task_id = t.id) AS assignee_uids
  FROM task t
  LEFT JOIN task_label tl ON tl.task_id = t.id
  WHERE t.id = _id
  GROUP BY t.id;
END$
DELIMITER ;
