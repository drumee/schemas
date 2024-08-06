DELIMITER $

-- =========================================================
-- Get user's home (top) directory
-- =========================================================
DROP PROCEDURE IF EXISTS `mfs_home`$
CREATE PROCEDURE `mfs_home`(
)
BEGIN
  DECLARE _area VARCHAR(25);

  DECLARE _home_dir VARCHAR(500);
  DECLARE _name VARCHAR(500);

  DECLARE _home_id VARCHAR(16) CHARACTER SET ascii; 
  DECLARE _chat_upload_id VARCHAR(16) CHARACTER SET ascii; 
  DECLARE _chat_id VARCHAR(16) CHARACTER SET ascii; 
  DECLARE _ticket_id VARCHAR(16) CHARACTER SET ascii; 

  DECLARE _entity_id VARCHAR(16) CHARACTER SET ascii;
  SELECT id  FROM media WHERE parent_id='0' INTO _home_id;
  SELECT node_id_from_path('/__chat__/__upload__') INTO _chat_upload_id;
  SELECT node_id_from_path('/__chat__/') INTO _chat_id;
  SELECT node_id_from_path('/__ticket__/') INTO _ticket_id;
  
  SELECT id, area, home_dir FROM yp.entity WHERE db_name=database() INTO _entity_id, _area, _home_dir; 
 
  SELECT name FROM  yp.hub  WHERE id = _entity_id  INTO _name;

  IF _name IS NULL THEN 
     SELECT CONCAT(firstname, ' ', lastname) FROM yp.drumate 
     WHERE id = _entity_id  INTO _name;
  END IF;
  
  IF _chat_id IS NULL THEN
    CALL mfs_make_dir(_home_id, JSON_ARRAY('__chat__'), 0);
    SELECT node_id_from_path('/__chat__/') INTO _chat_id;
  END IF;

  IF _chat_upload_id IS NULL THEN
    CALL mfs_make_dir(_home_id, JSON_ARRAY('__chat__', '__upload__'), 0);
    SELECT node_id_from_path('/__chat__/__upload__') INTO _chat_upload_id;
  END IF;
  
  SELECT yp.get_vhost(_entity_id) vhost, 
    _entity_id AS hub_id, 
    _area area, 
    _home_dir home_dir, 
    _name AS `name`,
    _home_id AS home_id,
    _chat_upload_id chat_upload_id,
    _chat_id  chat_id,
    _ticket_id ticket_id;
    
END $

DELIMITER ;




