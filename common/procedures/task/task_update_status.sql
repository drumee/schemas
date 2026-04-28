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
    id, title, status, due_date, created_by, rank, ctime, mtime
  FROM task
  WHERE id = _id;
END$
DELIMITER ;