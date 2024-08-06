DELIMITER $


DROP PROCEDURE IF EXISTS `dmz_remove_member`$
CREATE PROCEDURE `dmz_remove_member`(
  IN _guest_id VARCHAR(50),
  IN _hub_id    VARCHAR(16),
  IN _node_id   VARCHAR(16)
)
BEGIN
  DECLARE _owner_id VARCHAR(50); 

  SELECT owner_id FROM yp.hub 
    WHERE id IN(SELECT id FROM yp.entity WHERE db_name = DATABASE())
    INTO _owner_id;

  DELETE FROM permission WHERE entity_id = _guest_id  AND entity_id <> _owner_id; 
  
  DELETE FROM yp.dmz_token WHERE hub_id = _hub_id AND 
   guest_id = _guest_id AND node_id = _node_id;

END$



DELIMITER ;




