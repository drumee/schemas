DELIMITER $

DROP PROCEDURE IF EXISTS `socket_free`$
CREATE PROCEDURE `socket_free`(
  IN _id VARCHAR(80)
)
BEGIN 
  DELETE FROM socket WHERE id=_id;
  DELETE FROM conference WHERE socket_id =_id;
END$

DELIMITER ;