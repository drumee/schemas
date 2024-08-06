DELIMITER $
DROP PROCEDURE IF EXISTS `hubname_exists`$
CREATE PROCEDURE `hubname_exists`(
  IN _key VARCHAR(128),
  IN _domain VARCHAR(128)
)
BEGIN
  DECLARE _dom_id INTEGER DEFAULT 1;
  SELECT domain_id FROM organisation WHERE domain_id=_domain OR link=_domain INTO _dom_id;
  SELECT id, hubname FROM hub WHERE hubname=_key AND domain_id = _dom_id;
END$
DELIMITER ;