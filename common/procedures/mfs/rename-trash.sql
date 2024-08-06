DELIMITER $

-- ==============================================================
-- Action to renaming  trash node while copy the same file/folder name from desk  
-- ==============================================================
DROP PROCEDURE IF EXISTS `rename_trash`$
CREATE PROCEDURE `rename_trash`(
  IN _src_id VARCHAR(16),
  IN _src_entity_id VARCHAR(16),
  IN _dest_pid VARCHAR(16),
  IN _des_entity_id VARCHAR(16)
  )
BEGIN
  DECLARE _category VARCHAR(40);
  DECLARE _src_db   VARCHAR(255);
  DECLARE _des_db   VARCHAR(255);
 
  
  SELECT db_name from yp.entity WHERE id=_src_entity_id INTO _src_db;
  SELECT db_name from yp.entity WHERE id=_des_entity_id INTO _des_db;
  SELECT NULL,NULL,NULL,NULL INTO @user_filename, @nid, @parent_id,@newfilename;
    
	
    SET @sql = CONCAT(
    " SELECT  destination.user_filename ,destination.id ,destination.parent_id
          
        FROM ",_src_db,".media source
            INNER JOIN ",_des_db,".media destination ON destination.user_filename= source.user_filename
            AND source.category = destination.category AND destination.status  = 'deleted'
        WHERE 
          source.id =",QUOTE(_src_id)," AND
          destination.parent_id=",QUOTE(_dest_pid), " INTO @user_filename, @nid, @parent_id "  );
          
    PREPARE stmt FROM @sql ;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    

   IF @user_filename IS NOT NULL THEN
  
	   SET @sql = CONCAT("SELECT ", _des_db , ".unique_filename( @parent_id,  @user_filename) into @newfilename") ;  
	   PREPARE stmt FROM @sql ;
	   EXECUTE stmt;
	   DEALLOCATE PREPARE stmt;
	   SELECT @user_filename, @nid, @parent_id ,@newfilename ;
	   
	   SET @sql = CONCAT("call ",_des_db ,".mfs_rename(@nid ,@newfilename )" );
	   PREPARE stmt FROM @sql ;
	   EXECUTE stmt;
	   DEALLOCATE PREPARE stmt;
	   SELECT NULL,NULL,NULL,NULL INTO @user_filename, @nid, @parent_id,@newfilename;
   END IF ;

END $




DELIMITER ;