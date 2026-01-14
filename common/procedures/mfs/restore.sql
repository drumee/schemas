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

    -- Update disk_usage when restoring from trash
    -- Trigger will auto-sync quota_usage
    BEGIN
      DECLARE _hub_id VARCHAR(16);
      DECLARE _total_filesize BIGINT DEFAULT 0;
      
      SELECT id FROM yp.entity WHERE db_name=database() INTO _hub_id;
      
      IF _category = 'folder' THEN
        -- Sum all files in folder
        SELECT COALESCE(SUM(filesize), 0)
        FROM media
        WHERE CONCAT(parent_path(id), user_filename) LIKE CONCAT(_node_path, '/%')
          OR id = _id
        INTO _total_filesize;
      ELSE
        -- Single file
        SELECT filesize FROM media WHERE id = _id INTO _total_filesize;
      END IF;
      
      IF _hub_id IS NOT NULL AND _total_filesize > 0 THEN
        UPDATE yp.disk_usage 
        SET size = IFNULL(size, 0) + _total_filesize 
        WHERE hub_id = _hub_id;
      END IF;
    END;

    -- Cleanup trash_media after successful restore
    BEGIN
      IF _category = 'folder' THEN
        -- Delete folder and all its children from trash_media
        DELETE FROM trash_media 
        WHERE id = _id 
          OR CONCAT(parent_path(id), user_filename) LIKE CONCAT(_node_path, '/%');
      ELSE
        -- Delete single file
        DELETE FROM trash_media WHERE id = _id;
      END IF;
    END;

  ELSE 
    SELECT 1 failed, "Could not restore root itself";
  END IF;
END $


DELIMITER ;