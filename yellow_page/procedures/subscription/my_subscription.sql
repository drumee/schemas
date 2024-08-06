DELIMITER $



DROP PROCEDURE IF EXISTS `my_subscription`$
CREATE PROCEDURE `my_subscription`(
   IN _uid VARCHAR(16)
)
BEGIN
  SELECT * FROM subscription WHERE uid = _uid;   
END$


DELIMITER ;