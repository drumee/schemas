DELIMITER $

DROP PROCEDURE IF EXISTS `seo_cleanup_folder_recursive`$
CREATE PROCEDURE `seo_cleanup_folder_recursive`(
  IN _hub_id VARCHAR(16),
  IN _folder_id VARCHAR(16)
)
BEGIN
  DECLARE _deleted_words INT DEFAULT 0;
  DECLARE _deleted_register INT DEFAULT 0;
  
  -- Delete indexes for all files in this folder (recursive)
  
  DROP TEMPORARY TABLE IF EXISTS _folder_files;
  CREATE TEMPORARY TABLE _folder_files (
    nid VARCHAR(16),
    category VARCHAR(50),
    INDEX(nid)
  ) ENGINE=MEMORY;
  
  -- Insert root folder
  INSERT INTO _folder_files (nid, category)
  SELECT id, category FROM media WHERE id = _folder_id;
  
  -- Recursive: get all children
  INSERT INTO _folder_files (nid, category)
  WITH RECURSIVE file_tree AS (
    SELECT id, category FROM media WHERE id = _folder_id
    UNION ALL
    SELECT m.id, m.category 
    FROM media m
    INNER JOIN file_tree ft ON m.parent_id = ft.id
    WHERE m.category NOT IN ('hub', 'root')
  )
  SELECT id, category FROM file_tree WHERE category NOT IN ('folder', 'hub', 'root');
  
  -- Batch delete from seo_index (only actual files, not folders)
  DELETE si FROM seo_index si
  INNER JOIN _folder_files ff ON si.nid = ff.nid
  WHERE si.hub_id = _hub_id 
    AND ff.category NOT IN ('folder', 'hub', 'root');
  
  SET _deleted_words = ROW_COUNT();
  
  -- Batch delete from seo_register
  DELETE sr FROM seo_register sr
  INNER JOIN _folder_files ff ON sr.nid = ff.nid
  WHERE sr.hub_id = _hub_id
    AND ff.category NOT IN ('folder', 'hub', 'root');
  
  SET _deleted_register = ROW_COUNT();
  
  DROP TEMPORARY TABLE IF EXISTS _folder_files;
  
  SELECT 
    _deleted_words AS deleted_words,
    _deleted_register AS deleted_register,
    'success' AS status;
END$

DELIMITER ;