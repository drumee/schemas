DELIMITER $


DROP PROCEDURE IF EXISTS `dmz_update_password`$
CREATE PROCEDURE `dmz_update_password`(
  IN _hub_id    VARCHAR(16),
  IN _node_id   VARCHAR(16),
  IN _pw        VARCHAR(250)
)
BEGIN
  UPDATE dmz_token 
    SET fingerprint=sha2(IF(_pw='', NULL, _pw), 512)
  WHERE 
    hub_id=_hub_id ;  --  AND node_id=_node_id;
END$


DELIMITER ;