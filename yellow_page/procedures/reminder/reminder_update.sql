DELIMITER $

DROP PROCEDURE IF EXISTS `reminder_update`$
CREATE PROCEDURE `reminder_update`(
  IN _id VARCHAR(16),
  IN _task JSON
)
BEGIN
  UPDATE reminder SET task=JSON_MERGE_PATCH(task, _task, JSON_OBJECT('mtime', UNIX_TIMESTAMP())) WHERE id=_id;
  SELECT * FROM reminder WHERE id=_id;
END$

DELIMITER ;

-- #####################
