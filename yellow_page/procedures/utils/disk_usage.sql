DELIMITER $
-- =========================================================
-- 
-- =========================================================
DROP FUNCTION IF EXISTS `disk_usage`$
CREATE FUNCTION `disk_usage`(
  _uid VARCHAR(16) 
) RETURNS FLOAT DETERMINISTIC
BEGIN 
  DECLARE _res FLOAT;
  DECLARE _user FLOAT;
  SELECT SUM(du.size) FROM disk_usage du 
    LEFT JOIN(entity e, hub h) ON hub_id=e.id 
    AND h.id = e.id 
    WHERE h.owner_id=_uid INTO _res;
    
  SELECT SUM(du.size) FROM disk_usage du 
    LEFT JOIN drumate d ON hub_id=d.id 
    WHERE d.id=_uid INTO _user;
  
  RETURN _res + _user;
END$

DELIMITER ;


