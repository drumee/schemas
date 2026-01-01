-- File: schemas/common/procedures/mfs/mfs_node_summary.sql
-- Purpose: Get comprehensive information about a folder/node
-- Returns: file count, members, total size, ctime, mtime

DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_node_info`$
DROP PROCEDURE IF EXISTS `mfs_node_summary`$

CREATE PROCEDURE `mfs_node_summary`(
  IN _nid VARCHAR(16)
)
BEGIN
  DECLARE _file_count INT DEFAULT 0;
  DECLARE _total_size BIGINT DEFAULT 0;
  DECLARE _ctime INT(11) UNSIGNED;
  DECLARE _mtime INT(11) UNSIGNED;
  
  -- Get folder's own ctime and initial mtime
  SELECT upload_time, publish_time 
  FROM media 
  WHERE id = _nid
  INTO _ctime, _mtime;
  
  -- Count files recursively (excluding folders and hubs)
  -- Get total size and most recent mtime
  WITH RECURSIVE folder_tree AS (
    SELECT id, parent_id, category, filesize, publish_time, status
    FROM media
    WHERE id = _nid
    
    UNION ALL
    
    -- Recursively get all children
    SELECT m.id, m.parent_id, m.category, m.filesize, m.publish_time, m.status
    FROM media m
    INNER JOIN folder_tree ft ON m.parent_id = ft.id
    WHERE m.status NOT IN ('hidden', 'deleted')
  )
  SELECT 
    COUNT(CASE WHEN category NOT IN ('folder', 'hub', 'root') THEN 1 END),
    IFNULL(SUM(CASE WHEN category NOT IN ('folder', 'hub', 'root') THEN filesize ELSE 0 END), 0),
    IFNULL(MAX(publish_time), _mtime)
  FROM folder_tree
  WHERE status NOT IN ('hidden', 'deleted')
  INTO _file_count, _total_size, _mtime;
  
  SELECT 
    _file_count AS file_count,
    _total_size AS total_size,
    _ctime AS ctime,
    _mtime AS mtime,
    IFNULL(
      JSON_ARRAYAGG(
        JSON_OBJECT(
          'id', d.id,
          'firstname', d.firstname,
          'lastname', d.lastname,
          'email', d.email,
          'permission', p.permission,
          'expiry_time', p.expiry_time
        )
      ),
      JSON_ARRAY()
    ) AS members
  FROM permission p
  LEFT JOIN yp.drumate d ON p.entity_id = d.id
  WHERE p.resource_id = _nid
    AND (p.expiry_time = 0 OR p.expiry_time > UNIX_TIMESTAMP());
    
END$

DELIMITER ;