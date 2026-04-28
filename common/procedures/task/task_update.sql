DELIMITER $
DROP PROCEDURE IF EXISTS `task_update`$
CREATE PROCEDURE `task_update`(
  IN _id VARCHAR(16),
  IN _title VARCHAR(500),
  IN _due_date DATE
)
BEGIN
  UPDATE task
     SET title = IFNULL(_title, title),
         due_date = _due_date,
         mtime = UNIX_TIMESTAMP()
   WHERE id = _id;

  SELECT
    id, title, status, due_date, created_by, rank, ctime, mtime
  FROM task
  WHERE id = _id;
END$
DELIMITER ;