-- File: schemas/common/procedures/mfs/mfs_contact_summary.sql
-- Purpose: Get contact folder summary (count + last update)

DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_contact_summary`$

CREATE PROCEDURE `mfs_contact_summary`(
  IN _hub_id VARCHAR(16),
  IN _nid VARCHAR(16)
)
BEGIN
  DECLARE _contact_count INT DEFAULT 0;
  DECLARE _last_updated INT(11) UNSIGNED DEFAULT 0;
  
  -- Count contacts in the folder (recursively)
  -- Get the most recent mtime (publish_time)
  WITH RECURSIVE folder_tree AS (
    SELECT id, parent_id, category, publish_time, status
    FROM media
    WHERE id = _nid
    
    UNION ALL
    
    -- Recursively get all children
    SELECT m.id, m.parent_id, m.category, m.publish_time, m.status
    FROM media m
    INNER JOIN folder_tree ft ON m.parent_id = ft.id
    WHERE m.status NOT IN ('hidden', 'deleted')
  )
  SELECT 
    COUNT(CASE WHEN category NOT IN ('folder', 'hub', 'root') THEN 1 END),
    IFNULL(MAX(publish_time), 0)
  FROM folder_tree
  WHERE status NOT IN ('hidden', 'deleted')
  INTO _contact_count, _last_updated;
  
  SELECT 
    _contact_count AS contact_count,
    _last_updated AS last_updated;
    
END$

DELIMITER ;