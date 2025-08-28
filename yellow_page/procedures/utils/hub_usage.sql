DELIMITER $
-- =========================================================
-- 
-- =========================================================
DROP FUNCTION IF EXISTS `hub_usage`$
CREATE FUNCTION `hub_usage`(
  _uid VARCHAR(16),
  _area VARCHAR(16)
) RETURNS INTEGER DETERMINISTIC
BEGIN 
  DECLARE _res INTEGER DEFAULT 0;
  SELECT count(*) FROM hub h INNER JOIN entity e USING(id) WHERE owner_id=_uid AND area=_area INTO _res;
  RETURN _res;
END$

DELIMITER ;


