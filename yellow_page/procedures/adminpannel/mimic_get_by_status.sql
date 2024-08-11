DELIMITER $



DROP PROCEDURE IF EXISTS `mimic_get_by_status`$
CREATE PROCEDURE `mimic_get_by_status`(
  IN _uid  VARCHAR(16),
  IN _status   VARCHAR(50)
 )
BEGIN
    SELECT * FROM mimic WHERE (uid = _uid or mimicker = _uid) AND  status = _status;
END $



DELIMITER ;