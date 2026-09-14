DELIMITER $
DROP PROCEDURE IF EXISTS `notification_activity_bookmark_remove`$
CREATE PROCEDURE `notification_activity_bookmark_remove`(
  IN _bookmark_key CHAR(64) CHARACTER SET ascii
)
BEGIN
  DELETE FROM notification_activity_bookmark
  WHERE bookmark_key = _bookmark_key;

  SELECT _bookmark_key AS bookmark_key, 0 AS is_saved;
END$
DELIMITER ;
