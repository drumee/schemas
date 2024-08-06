-- =========================================================
-- Return domain to which an entity belongs to
-- =========================================================
DELIMITER $

DROP FUNCTION IF EXISTS `domain_id`$
CREATE FUNCTION `domain_id`(
  _key VARCHAR(1024)
)
RETURNS INTEGER DETERMINISTIC
BEGIN
  DECLARE _res INTEGER DEFAULT 1;
  SELECT o.domain_id FROM entity e INNER JOIN organisation o on e.dom_id=o.domain_id 
  WHERE e.id=_key OR db_name=_key INTO _res;
  RETURN _res;
END$

DELIMITER ;
