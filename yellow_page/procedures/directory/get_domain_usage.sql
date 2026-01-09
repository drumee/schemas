-- Get cached domain usage from quota_usage table
-- For paid plans only (domain_id > 1)
-- Free users (domain_id = 1) have individual quotas

DELIMITER $

USE yp$

DROP PROCEDURE IF EXISTS `get_domain_usage`$

CREATE PROCEDURE `get_domain_usage`(
  IN _domain_id INT
)
BEGIN
  DECLARE _usage BIGINT DEFAULT 0;
  
  IF _domain_id IS NULL OR _domain_id = 1 THEN
    SELECT JSON_OBJECT(
      'total', 0,
      'domain_id', 1,
      'error', 'Free users have individual quotas'
    ) AS `usage`;
  ELSE
    SELECT COALESCE(cached_usage, 0)
    FROM quota_usage
    WHERE domain_id = _domain_id
    INTO _usage;
    
    IF _usage IS NULL THEN
      INSERT INTO quota_usage (domain_id, cached_usage, ctime, mtime)
      VALUES (_domain_id, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
      ON DUPLICATE KEY UPDATE cached_usage = 0;
      
      SELECT 0 INTO _usage;
    END IF;
    
    SELECT JSON_OBJECT(
      'total', _usage,
      'domain_id', _domain_id
    ) AS `usage`;
  END IF;
END$

DELIMITER ;