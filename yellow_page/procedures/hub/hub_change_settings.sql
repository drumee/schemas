DELIMITER $

DROP PROCEDURE IF EXISTS `hub_change_settings`$
CREATE PROCEDURE `hub_change_settings`(
  IN _hub_id    VARCHAR(16),
  IN _name      VARCHAR(100),
  IN _value     VARCHAR(1024)
)
BEGIN
  UPDATE entity SET 
    `settings`=JSON_SET(`settings`, CONCAT("$.", _name), _value) 
  WHERE id=_hub_id;
  SELECT id, settings FROM entity WHERE id=_hub_id;
END $
DELIMITER ;
