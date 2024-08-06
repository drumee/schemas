DELIMITER $
DROP PROCEDURE IF EXISTS `show_all_members`$
CREATE PROCEDURE `show_all_members`(
)
BEGIN
  DECLARE _hub_id VARCHAR(16);
  SELECT id FROM yp.entity WHERE db_name=DATABASE() INTO _hub_id;

  SELECT   
    d.id,
    e.db_name AS db_name,
    _hub_id AS nid,
    permission AS privilege,
    read_json_object(d.profile, 'firstname') AS firstname,
    read_json_object(d.profile, 'lastname') AS lastname
    
  FROM permission p 
  INNER JOIN yp.drumate d ON p.entity_id=d.id 
  INNER JOIN yp.entity e ON e.id=d.id
  WHERE resource_id='*' ;
END$

DELIMITER ;
