-- File: schemas/drumate/procedures/contact/contact_summary.sql
-- Purpose: Get contact summary from contact table

DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_contact_summary`$
DROP PROCEDURE IF EXISTS `contact_summary`$

CREATE PROCEDURE `contact_summary`(
  IN _hub_id VARCHAR(16),
  IN _nid VARCHAR(16)
)
BEGIN
  DECLARE _contact_count INT DEFAULT 0;
  DECLARE _last_updated INT(11) UNSIGNED DEFAULT 0;
  
  -- Note: _hub_id and _nid are for permission check in service layer  
  -- Count active contacts and get most recent mtime
  SELECT 
    COUNT(*),
    IFNULL(MAX(mtime), 0)
  FROM contact
  WHERE status IN ('active', 'informed', 'accept')
  INTO _contact_count, _last_updated;
  
  SELECT 
    _contact_count AS contact_count,
    _last_updated AS last_updated;
    
END$

DELIMITER ;