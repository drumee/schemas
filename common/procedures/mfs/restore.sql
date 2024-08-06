DELIMITER $

-- ==============================================================
-- Restore delete media from trash, positionin tree is unchanged
-- ==============================================================


DROP PROCEDURE IF EXISTS `mfs_restore`$
CREATE PROCEDURE `mfs_restore`(
  IN _id VARCHAR(16)
)
BEGIN
  
  DECLARE _category VARCHAR(40);
  DECLARE _node_path VARCHAR(6000);
  DECLARE _trash_parent_parent_path VARCHAR(6000);
  DECLARE _trash_parent_id VARCHAR(16);
  DECLARE _restore_parent_id VARCHAR(16);
  DECLARE _home_id VARCHAR(16);
  
  DECLARE _temp_id VARCHAR(16);
  DECLARE _trash_home_id VARCHAR(16);

  DECLARE _lvl INT;

  SELECT node_id_from_path('/__trash__') INTO _trash_home_id;
  
  SELECT category INTO _category FROM media t WHERE id = _id;
  SELECT id INTO _home_id FROM media t WHERE ( parent_id IS NULL OR parent_id="" OR parent_id='0');

  IF _id <> _home_id THEN 
    SELECT 
      id,
      clean_path(concat(parent_path(t.id), '/', t.user_filename))
    INTO 
      _trash_parent_id, 
      _trash_parent_parent_path 
    FROM media t WHERE id=(SELECT parent_id FROM media WHERE id = _id); 
    

    IF _trash_parent_id = _trash_home_id THEN 
      SELECT id FROM media WHERE ( parent_id IS NULL OR parent_id="" OR parent_id='0') INTO _restore_parent_id;
    ELSE  
      SELECT node_id_from_path(REPLACE(_trash_parent_parent_path,'/__trash__','')) INTO _restore_parent_id;
    END IF; 


    UPDATE media SET parent_id=_restore_parent_id, status='active' WHERE id=_id;  
    UPDATE media SET parent_path = parent_path(id),file_path = clean_path(concat(parent_path(id), '/', user_filename, '.', extension)) 
    WHERE id = _id;

    IF _category='folder' THEN
      SELECT CONCAT(parent_path(id),user_filename) FROM media WHERE id=_id INTO _node_path;
      UPDATE media 
        SET parent_path = parent_path(id),file_path = clean_path(concat(parent_path(id), '/', user_filename, '.', extension)), status='active'
      WHERE CONCAT(parent_path(id),user_filename ) LIKE concat(_node_path, '/%'); 
    END IF;

    WHILE  _trash_parent_id <> _trash_home_id AND IFNULL(_lvl,0) < 1000 DO 
      SELECT NULL INTO _temp_id;
      SELECT parent_id FROM media WHERE id =_trash_parent_id INTO _temp_id; 
      DELETE FROM media WHERE id = _trash_parent_id  AND  CONCAT(parent_path(id),user_filename ) LIKE concat('/__trash__', '/%'); 
      SELECT _temp_id INTO _trash_parent_id;
      SELECT IFNULL(_lvl,0) +1  INTO _lvl;
    END WHILE;
  ELSE 
    SELECT 1 failed, "Could not restore root itself";
  END IF;
END $


DELIMITER ;