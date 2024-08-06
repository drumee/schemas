DELIMITER $


DROP PROCEDURE IF EXISTS `dmz_revoke_privileges`$
CREATE PROCEDURE `dmz_revoke_privileges`(
  IN _resource_id VARCHAR(50)
)
BEGIN
  DECLARE _owner_id VARCHAR(50); 

  SELECT owner_id FROM yp.hub 
    WHERE id IN(SELECT id FROM yp.entity WHERE db_name = DATABASE())
    INTO _owner_id;

  DELETE FROM permission WHERE resource_id = _resource_id  AND entity_id <> _owner_id; 

END$




DROP PROCEDURE IF EXISTS `dmz_remove_user`$
DROP PROCEDURE IF EXISTS `dmz_sync_grant`$
CREATE PROCEDURE `dmz_sync_grant`(
  IN _resource_id VARCHAR(50)
)
BEGIN
  DECLARE _owner_id VARCHAR(50); 

  DELETE FROM  yp.dmz_token  WHERE node_id = _resource_id
  AND guest_id  NOT IN (
  SELECT  entity_id FROM permission WHERE resource_id = _resource_id );

END$


DELIMITER ;




