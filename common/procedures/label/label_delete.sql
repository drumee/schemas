DELIMITER $
DROP PROCEDURE IF EXISTS `label_delete`$
CREATE PROCEDURE `label_delete`(
  IN _id VARCHAR(16)
)
BEGIN
  -- Explicitly remove junction rows first
  DELETE FROM task_label WHERE label_id = _id;
  DELETE FROM label      WHERE id       = _id;
  SELECT ROW_COUNT() AS affected;
END$
DELIMITER ;
