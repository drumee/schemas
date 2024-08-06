DELIMITER $

--  DROP PROCEDURE IF EXISTS `dmz_update_permission`$
DROP PROCEDURE IF EXISTS `dmz_update_permission_next`$
CREATE PROCEDURE `dmz_update_permission_next`(
  IN _hub_id    VARCHAR(16),
  IN _node_id   VARCHAR(16),
  IN _permission  INTEGER
)
BEGIN
  DECLARE _db_name VARCHAR(30);
  DECLARE _owner_id VARCHAR(30);
  
  SELECT db_name FROM entity WHERE id=_hub_id 
    INTO _db_name;

  SELECT owner_id FROM hub WHERE id=_hub_id 
    INTO _owner_id;
 
  SELECT cast(_permission as unsigned) INTO @perm;

  SET @s = CONCAT("UPDATE ", 
    _db_name,".permission SET ",
    "permission=?  "
    "WHERE entity_id <> ? AND resource_id=? AND  assign_via <> 'no_traversal' ");
  PREPARE stmt FROM @s;
  EXECUTE stmt USING  @perm, _owner_id, _node_id;
  DEALLOCATE PREPARE stmt; 

  SET @s = CONCAT("UPDATE ", 
    _db_name,".permission p",
    " INNER JOIN ",_db_name ,".media m ON m.id = p.entity_id 
     INNER JOIN yp.dmz_media d ON m.id=d.id 
    SET p.permission= IF( m.category <> 'folder' AND @perm > 3 , 3 ,@perm )
    WHERE d.hub_id =?");
  PREPARE stmt FROM @s;
  EXECUTE stmt USING   _hub_id;
  DEALLOCATE PREPARE stmt;

END$


DELIMITER ;