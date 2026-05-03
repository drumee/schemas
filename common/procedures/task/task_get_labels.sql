DELIMITER $
DROP PROCEDURE IF EXISTS `task_get_labels`$
CREATE PROCEDURE `task_get_labels`(
  IN _task_id VARCHAR(16)
)
BEGIN
  SELECT
    tl.task_id,
    tl.label_id,
    tl.ctime,
    l.name,
    l.color
  FROM task_label tl
  LEFT JOIN label l ON l.id = tl.label_id
  WHERE tl.task_id = _task_id
  ORDER BY tl.ctime ASC;
END$
DELIMITER ;
