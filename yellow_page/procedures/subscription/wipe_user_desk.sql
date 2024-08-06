DELIMITER $


  DROP PROCEDURE IF EXISTS `wipe_user_desk`$
  CREATE PROCEDURE `wipe_user_desk`(
    IN _id VARCHAR(16)
    )
  BEGIN
    DECLARE _user_db VARCHAR(100);

    SELECT db_name FROM yp.entity WHERE id = _id INTO _user_db;

    SELECT  NULL, NULL,NULL,NULL,NULL  INTO 
    @home_id , @chat_upload_is,  @chat_id , @ticket_id,@wicket_id;

 
    SELECT h.id FROM 
      yp.hub h INNER JOIN yp.entity e on e.id=h.id
    WHERE h.owner_id=_id AND `serial`=0
    INTO @wicket_id;

    SET @s = CONCAT("SELECT id  from `", _user_db, 
      "`.media WHERE  parent_id='0' INTO @home_id");
    PREPARE stmt FROM @s  ;
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt;

    SET @s = CONCAT("SELECT `", _user_db, 
      "`.node_id_from_path('/__chat__/__upload__') INTO @chat_upload_id");
    PREPARE stmt FROM @s  ;
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt;


    SET @s = CONCAT("SELECT `", _user_db, 
      "`.node_id_from_path('/__chat__/') INTO @chat_id");
    PREPARE stmt FROM @s  ;
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt;


    SET @s = CONCAT("SELECT `", _user_db, 
      "`.node_id_from_path('/__ticket__/') INTO @ticket_id");
    PREPARE stmt FROM @s  ;
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt;


    SET @s = CONCAT("DELETE FROM ", _user_db, 
      ".media WHERE id <> IFNULL(@home_id, '-99') 
      AND id <> IFNULL(@chat_upload_id, '-99') 
      AND id <> IFNULL(@chat_id, '-99') 
      AND id <> IFNULL(@wicket_id, '-99')
      AND id <> IFNULL(@ticket_id, '-99' ) ");
    PREPARE stmt FROM @s ; 
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt;


    SET @s = CONCAT("DELETE FROM ", _user_db, 
      ".trash_media ");
    PREPARE stmt FROM @s ; 
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt;

    SELECT  NULL, NULL,NULL,NULL,NULL  INTO 
    @home_id , @chat_upload_is,  @chat_id , @ticket_id,@wicket_id;
    
  
  END $


DELIMITER ;

