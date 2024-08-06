
DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_hub_chat_init`$
CREATE PROCEDURE `mfs_hub_chat_init`()
BEGIN
 
  SELECT node_id_from_path('/__chat__') INTO @temp_chat_id;

  IF @temp_chat_id IS NULL THEN 
    call mfs_make_dir("0", JSON_ARRAY('__chat__'), 0);
    UPDATE media SET status='hidden' WHERE file_path='/__chat__';
  END IF;
  
  SELECT node_id_from_path('/__chat__') INTO @temp_chat_id;
  SELECT node_id_from_path('/__chat__/__upload__') INTO @temp_upload_id;

 
  IF @temp_upload_id IS NULL THEN 
    CALL mfs_make_dir(@temp_chat_id, JSON_ARRAY("__upload__"), 0);
    UPDATE media set status='hidden' WHERE file_path='/__chat__/__upload__';
  END IF;

END$

DELIMITER ;
