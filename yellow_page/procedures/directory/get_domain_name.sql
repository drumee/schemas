-- =========================================================
-- Return domain to which an entity belongs to
-- =========================================================
DELIMITER $

DROP FUNCTION IF EXISTS `get_domain_name`$
CREATE FUNCTION `get_domain_name`(
  _key VARCHAR(1024)
)
RETURNS VARCHAR(1024) DETERMINISTIC
BEGIN
  DECLARE _res VARCHAR(1024);
  SELECT d.name FROM entity e INNER JOIN domain d on e.dom_id=d.id
  WHERE e.id=_key OR db_name=_key INTO _res;
  RETURN _res;
END$

DELIMITER ;
