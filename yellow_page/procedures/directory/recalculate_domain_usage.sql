-- Recalculate actual domain usage and sync cache
-- Run periodically (hourly) to fix any drift

DELIMITER $

USE yp$

DROP PROCEDURE IF EXISTS `recalculate_domain_usage`$

CREATE PROCEDURE `recalculate_domain_usage`(
  IN _domain_id INT
)
BEGIN
  DECLARE _total BIGINT DEFAULT 0;
  DECLARE _old_cached BIGINT DEFAULT 0;
  DECLARE _drift BIGINT DEFAULT 0;
  
  IF _domain_id IS NULL OR _domain_id = 1 THEN
    SELECT JSON_OBJECT(
      'error', 'Cannot recalculate for free users domain'
    ) AS result;
  ELSE
    SELECT COALESCE(cached_usage, 0)
    FROM quota_usage
    WHERE domain_id = _domain_id
    INTO _old_cached;
    
    SELECT COALESCE(SUM(du.size), 0)
    FROM disk_usage du
    INNER JOIN entity e ON du.hub_id = e.id
    WHERE e.domain_id = _domain_id
    INTO _total;
    
    SELECT _total - _old_cached INTO _drift;
    
    INSERT INTO quota_usage (
      domain_id, 
      cached_usage, 
      actual_usage, 
      drift,
      last_recalc,
      ctime,
      mtime
    )
    VALUES (
      _domain_id,
      _total,
      _total,
      0,
      UNIX_TIMESTAMP(),
      UNIX_TIMESTAMP(),
      UNIX_TIMESTAMP()
    )
    ON DUPLICATE KEY UPDATE
      cached_usage = _total,
      actual_usage = _total,
      drift = 0,
      last_recalc = UNIX_TIMESTAMP(),
      mtime = UNIX_TIMESTAMP();
    
    SELECT JSON_OBJECT(
      'domain_id', _domain_id,
      'calculated_total', _total,
      'old_cached', _old_cached,
      'drift', _drift,
      'synced_at', UNIX_TIMESTAMP()
    ) AS result;
  END IF;
END$

DELIMITER ;