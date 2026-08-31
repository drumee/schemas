DELIMITER $
DROP PROCEDURE IF EXISTS `notification_activity_bookmark_list`$
CREATE PROCEDURE `notification_activity_bookmark_list`()
BEGIN
  SELECT bookmark_key
  FROM notification_activity_bookmark
  ORDER BY ctime DESC
  LIMIT 1000;
END$
DELIMITER ;
