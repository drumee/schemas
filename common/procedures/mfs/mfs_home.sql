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
  DECLARE _task_upload_id VARCHAR(16) CHARACTER SET ascii; 
  DECLARE _chat_id VARCHAR(16) CHARACTER SET ascii; 
  DECLARE _ticket_id VARCHAR(16) CHARACTER SET ascii; 

  DECLARE _entity_id VARCHAR(16) CHARACTER SET ascii;
  SELECT id  FROM media WHERE parent_id='0' INTO _home_id;
  SELECT node_id_from_path('/__chat__/__upload__') INTO _chat_upload_id;
  SELECT node_id_from_path('/__chat__/') INTO _chat_id;
  SELECT node_id_from_path('/__ticket__/') INTO _ticket_id;
  -- Resolved by parent + name, NOT by a fourth node_id_from_path: that function
  -- matches on REPLACE(file_path,'/',''), which no index can serve, and mfs_home
  -- sits on hot ACL paths (permission.js `_start_with`). parent_id is indexed.
  -- _chat_id is NULL on a hub that has no /__chat__ yet; the lookup then finds
  -- nothing and the block below creates both, in order.
  SELECT id FROM media
    WHERE parent_id = _chat_id AND user_filename = '__task__'
    INTO _task_upload_id;
  
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

  -- Task attachments. A file attached to a task belongs to the task, not to
  -- the workspace body: uploading it into the folder the user happened to be
  -- standing in put it in that folder's Files tab, beside the real documents.
  -- It lands here instead — a sibling of the chat staging folder, so it
  -- inherits the '^/__chat__' exclusion every listing, search, export and
  -- manifest query already applies, and the hub's '*' member grant already
  -- covers reading and writing it.
  --
  -- Created lazily, exactly like __upload__ above, so an existing hub heals
  -- itself on the first call rather than needing a data migration.
  IF _task_upload_id IS NULL THEN
    -- Parented on _chat_id, resolved just above, rather than walking the path
    -- again: mfs_make_dir strips a trailing '.folder' off the parent it is
    -- handed, so this cannot mint a second '__chat__' beside the real one.
    CALL mfs_make_dir(_chat_id, JSON_ARRAY('__task__'), 0);
    SELECT id FROM media
      WHERE parent_id = _chat_id AND user_filename = '__task__'
      INTO _task_upload_id;
    -- By id, not by file_path: hub and drumate have written that column both
    -- with and without a trailing '.folder' for directories.
    UPDATE media SET status='hidden' WHERE id = _task_upload_id;
  END IF;
  
  SELECT yp.get_vhost(_entity_id) vhost, 
    _entity_id AS hub_id, 
    _area area, 
    _home_dir home_dir, 
    _name AS `name`,
    _home_id AS home_id,
    _chat_upload_id chat_upload_id,
    _task_upload_id task_upload_id,
    _chat_id  chat_id,
    _ticket_id ticket_id;
    
END $

DELIMITER ;




