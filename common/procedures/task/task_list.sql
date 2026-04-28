DELIMITER $
DROP PROCEDURE IF EXISTS `task_list`$
CREATE PROCEDURE `task_list`()
BEGIN
  SELECT
    id,
    title,
    status,
    due_date,
    created_by,
    rank,
    ctime,
    mtime
  FROM task
  ORDER BY
    FIELD(status, 'todo', 'in_progress', 'to_review', 'complete'),
    rank ASC,
    ctime ASC;
END$
DELIMITER ;