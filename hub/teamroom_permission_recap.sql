DELIMITER $


BEGIN NOT ATOMIC
DECLARE _is_private_hub INT DEFAULT 0;
DECLARE _sys_id INT DEFAULT 0;
DECLARE _temp_sys_id INT DEFAULT 0;
DECLARE _entity_id VARCHAR(16) CHARACTER SET ascii; 
DECLARE _chat_upload_id VARCHAR(16) CHARACTER SET ascii; 

  SELECT node_id_from_path('/__chat__/__upload__') 
  INTO _chat_upload_id;

  SELECT  1  
    FROM yp.entity 
  WHERE 
    db_name = DATABASE() AND 
    area = 'private' AND 
    type = 'hub'
  INTO  _is_private_hub;

  IF (_is_private_hub = 1 AND _chat_upload_id IS NOT NULL) THEN 
    
    SELECT sys_id  FROM permission 
    WHERE resource_id = '*'  
    ORDER BY sys_id  ASC  LIMIT 1 INTO _sys_id  ;
  
    WHILE (_sys_id <> 0) DO

      SELECT entity_id  FROM permission 
      WHERE sys_id = _sys_id INTO _entity_id;

      CALL permission_grant(_chat_upload_id, _entity_id,0,4,
        'no_traversal','chat upload permission' );

      SELECT _sys_id INTO _temp_sys_id;
      SELECT 0 INTO _sys_id;
      SELECT sys_id  FROM permission 
      WHERE resource_id = '*'  
      AND sys_id > _temp_sys_id
      ORDER BY sys_id ASC  LIMIT 1 INTO _sys_id  ;

    END WHILE;

  END IF ;


END $
DELIMITER ;


