-- File: yellow_page/procedures/directory/create_or_update_quota.sql
-- Purpose: Create or update quota
DELIMITER $

DROP PROCEDURE IF EXISTS `create_payment`$

CREATE PROCEDURE `create_payment`(
  IN _invoice_id VARCHAR(255),
  IN _payer_id VARCHAR(16),
  IN _plan_name VARCHAR(16),
  IN _metadata JSON
)
BEGIN
  
  REPLACE INTO payment (
    invoice_id,
    payer_id,
    plan_name,
    metadata,
    ctime,
    mtime
  ) VALUES (
    _invoice_id,
    _payer_id,
    _plan_name,
    _metadata,
    UNIX_TIMESTAMP(),
    UNIX_TIMESTAMP()
  );
  
END$

DELIMITER ;
