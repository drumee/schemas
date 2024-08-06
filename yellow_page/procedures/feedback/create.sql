DELIMITER $


-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `feedback_create`$
CREATE PROCEDURE `feedback_create`(
  IN _msg TEXT
)
BEGIN

  INSERT INTO feedback SELECT null, _msg,  UNIX_TIMESTAMP(),  UNIX_TIMESTAMP ();
  SELECT * FROM feedback ORDER BY ctime DESC LIMIT 1;
END$

DELIMITER ;