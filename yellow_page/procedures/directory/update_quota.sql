-- File: yellow_page/procedures/directory/create_or_update_quota.sql
-- Purpose: Create or update quota
DELIMITER $

DROP PROCEDURE IF EXISTS `update_quota`$

CREATE PROCEDURE `update_quota`(
  IN _id INT UNSIGNED,
  IN _domain_id INT UNSIGNED,
  IN _quota JSON
)
BEGIN
  UPDATE quota SET quota=_quota, domain_id=_domain_id, mtime=UNIX_TIMESTAMP() WHERE id=_id;
  SELECT * FROM quota WHERE id=_id;
  
END$

DELIMITER ;