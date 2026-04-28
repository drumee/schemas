DELIMITER $
DROP PROCEDURE IF EXISTS `task_create`$
CREATE PROCEDURE `task_create`(
  IN _id VARCHAR(16),
  IN _title VARCHAR(500),
  IN _status VARCHAR(20),
  IN _due_date DATE,
  IN _created_by VARCHAR(16)
)
BEGIN
  DECLARE _rank INT DEFAULT 0;
  DECLARE _now INT DEFAULT UNIX_TIMESTAMP();

  -- rank = max rank in same status column + 1 (places task at the bottom)
  SELECT IFNULL(MAX(rank), 0) + 1
    INTO _rank
    FROM task
   WHERE status = _status;

  INSERT INTO task (id, title, status, due_date, created_by, rank, ctime, mtime)
  VALUES (_id, _title, _status, _due_date, _created_by, _rank, _now, _now);

  SELECT
    id, title, status, due_date, created_by, rank, ctime, mtime
  FROM task
  WHERE id = _id;
END$
DELIMITER ;