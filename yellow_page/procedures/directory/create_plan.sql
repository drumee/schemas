-- File: yellow_page/procedures/directory/create_or_update_quota.sql
-- Purpose: Create or update quota
DELIMITER $

DROP PROCEDURE IF EXISTS `create_plan`$

CREATE PROCEDURE `create_plan`(
  IN _payer_id VARCHAR(16),
  IN _name VARCHAR(255),
  IN _quota_id JSON
)
BEGIN
  
  INSERT INTO quota (
    domain_id,
    payer_id,
    plan,
    quota,
    ctime,
    mtime
  ) VALUES (
    _domain_id,
    _payer_id,
    _plan,
    _quota,
    UNIX_TIMESTAMP(),
    UNIX_TIMESTAMP()
  );
  
  SELECT * FROM quota WHERE domain_id=_domain_id AND payer_id=_payer_id;
  
END$

DELIMITER ;