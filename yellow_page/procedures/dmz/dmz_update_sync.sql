DELIMITER $



DROP PROCEDURE IF EXISTS `dmz_update_sync`$
CREATE PROCEDURE `dmz_update_sync`(
  IN _token VARCHAR(100), 
  IN _value INT(4)
)
BEGIN
  DECLARE _ts INT(11);
  UPDATE `dmz_token` SET is_sync = _value
  WHERE id = _token; 

END$



DELIMITER ;




