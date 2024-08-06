DELIMITER $

DROP PROCEDURE IF EXISTS `dmz_update_settings`$
CREATE PROCEDURE `dmz_update_settings`(
  IN _hub_id      VARCHAR(16),
  IN _node_id     VARCHAR(16),
  IN _fingerprint VARCHAR(250),
  IN _expiry      INT(11),
  IN _permission  INTEGER
)
BEGIN

  DECLARE _db_name VARCHAR(30);
  DECLARE _owner_id VARCHAR(30);

  UPDATE dmz_token 
    SET fingerprint=IF(_fingerprint='', NULL, _fingerprint)
  WHERE 
    hub_id=_hub_id AND node_id=_node_id;
  
  SELECT db_name FROM entity WHERE id=_hub_id 
    INTO _db_name;

  SELECT owner_id FROM hub WHERE id=_hub_id 
    INTO _owner_id;

  SET @s = CONCAT("UPDATE ", 
    _db_name,".permission SET ",
    "permission=?, expiry_time=? ",
    "WHERE entity_id <> ? AND resource_id=?");
  PREPARE stmt FROM @s;
  EXECUTE stmt USING _permission, _expiry, _owner_id, _node_id;
  DEALLOCATE PREPARE stmt;  


END$

DELIMITER ;