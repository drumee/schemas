DELIMITER $
DROP PROCEDURE IF EXISTS `session_mimic_get`$
CREATE PROCEDURE `session_mimic_get`(
  IN _sid VARCHAR(64)
 )
BEGIN
  DECLARE _mimicker VARCHAR(64);
  DECLARE _mimic_id VARCHAR(16);
  SELECT mimicker FROM cookie WHERE id=_sid INTO _mimicker;
  SELECT m.* ,  estimatetime  FROM mimic m WHERE mimicker = _mimicker INTO _mimic_id; 
END $
DELIMITER ;