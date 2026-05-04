DELIMITER $
DROP PROCEDURE IF EXISTS `task_link_label`$
CREATE PROCEDURE `task_link_label`(
  IN _task_id VARCHAR(16),
  IN _label_id VARCHAR(16)
)
BEGIN
  INSERT IGNORE INTO task_label (task_id, label_id, ctime)
  VALUES (_task_id, _label_id, UNIX_TIMESTAMP());

  -- Return updated label list for this task
  SELECT
    tl.task_id,
    tl.label_id,
    tl.ctime,
    l.name,
    l.color
  FROM task_label tl
  LEFT JOIN label l ON l.id = tl.label_id
  WHERE tl.task_id = _task_id;
END$
DELIMITER ;
