DELIMITER $
DROP PROCEDURE IF EXISTS `watermark`$
CREATE PROCEDURE `watermark`(
  IN _type VARCHAR(10)
)
BEGIN
  SELECT COUNT(*) AS en FROM entity WHERE area='pool' AND  type = _type;
END$


DELIMITER ;
