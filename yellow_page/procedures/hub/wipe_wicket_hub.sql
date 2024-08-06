DELIMITER $


  DROP PROCEDURE IF EXISTS `wipe_wicket_hub`$
  CREATE PROCEDURE `wipe_wicket_hub`(
    IN _id VARCHAR(16)
    )
  BEGIN
    DECLARE _wicket_db VARCHAR(100);
    SELECT db_name FROM yp.entity WHERE id = _id INTO _wicket_db;

  
    SELECT  NULL, NULL,NULL,NULL  INTO 
    @home_id , @chat_upload_is,  @chat_id , @ticket_id;

    SET @s = CONCAT("SELECT id  from `", _wicket_db, 
      "`.media WHERE  parent_id='0' INTO @home_id");
    PREPARE stmt FROM @s  ;
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt;

    SET @s = CONCAT("SELECT `", _wicket_db, 
      "`.node_id_from_path('/__chat__/__upload__') INTO @chat_upload_id");
    PREPARE stmt FROM @s  ;
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt;


    SET @s = CONCAT("SELECT `", _wicket_db, 
      "`.node_id_from_path('/__chat__/') INTO @chat_id");
    PREPARE stmt FROM @s  ;
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt;


    SET @s = CONCAT("SELECT `", _wicket_db, 
      "`.node_id_from_path('/__ticket__/') INTO @ticket_id");
    PREPARE stmt FROM @s  ;
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt;


    SET @s = CONCAT("DELETE FROM ", _wicket_db, 
      ".media WHERE id <> IFNULL(@home_id, '-99') AND id <> IFNULL(@chat_upload_id, '-99') And id <> IFNULL(@chat_id, '-99') And id <> IFNULL(@ticket_id, '-99' ) ");
    --  select @s;
    PREPARE stmt FROM @s ; 
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt;

    SELECT  NULL, NULL,NULL,NULL  INTO 
    @home_id , @chat_upload_is,  @chat_id , @ticket_id;

  
  END $


DELIMITER ;

