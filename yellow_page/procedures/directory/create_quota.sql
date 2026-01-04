-- File: yellow_page/procedures/directory/create_or_update_quota.sql
-- Purpose: Create or update quota
DELIMITER $

DROP PROCEDURE IF EXISTS `create_quota`$

CREATE PROCEDURE `create_quota`(
  IN _domain_id INT UNSIGNED,
  IN _payer_id VARCHAR(16),
  IN _plan VARCHAR(255),
  IN _quota JSON
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
  )
  ON DUPLICATE KEY UPDATE
    domain_id=VALUES(domain_id),
    payer_id=VALUES(payer_id),
    plan=VALUES(plan),
    quota=VALUES(quota),
    mtime=VALUES(mtime);
  
  SELECT * FROM quota WHERE domain_id=_domain_id AND payer_id=_payer_id;
  
END$

DELIMITER ;