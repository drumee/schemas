
DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_hub_chat_init`$
CREATE PROCEDURE `mfs_hub_chat_init`()
BEGIN
 
  SELECT node_id_from_path('/__chat__') INTO @temp_chat_id;

  IF @temp_chat_id IS NULL THEN 
    call mfs_make_dir("0", JSON_ARRAY('__chat__'), 0);
    UPDATE media SET status='hidden' where file_path='/__chat__.folder';
  END IF;
  
  SELECT node_id_from_path('/__chat__') INTO @temp_chat_id;
  SELECT node_id_from_path('/__chat__/__upload__') INTO @temp_upload_id;

 
  IF @temp_upload_id IS NULL THEN 
    CALL mfs_make_dir(@temp_chat_id, JSON_ARRAY("__upload__"), 0);
    UPDATE media set status='hidden' where file_path='/__chat__/__upload__.folder';
  END IF;

  -- The task attachment folder, made here with the other two so a new hub is
  -- complete when desk_create_hub hands it over. mfs_home creates it lazily
  -- for older hubs, and mfs_home is the first call of every hub-scoped ACL
  -- check: left to it, the first two requests on a new hub both find it
  -- missing and both try to create it, and the second is never answered.
  -- Same lookup and same steps as mfs_home, so the two agree on what exists.
  -- Reset first: SELECT ... INTO leaves a session variable untouched when no
  -- row matches, so a value from an earlier call would skip the create.
  SET @temp_task_id = NULL;
  SELECT id FROM media
    WHERE parent_id = @temp_chat_id AND user_filename = '__task__'
    INTO @temp_task_id;

  IF @temp_task_id IS NULL THEN
    CALL mfs_make_dir(@temp_chat_id, JSON_ARRAY('__task__'), 0);
    SELECT id FROM media
      WHERE parent_id = @temp_chat_id AND user_filename = '__task__'
      INTO @temp_task_id;
    UPDATE media SET status='hidden' WHERE id = @temp_task_id;
  END IF;

END$

DELIMITER ;
