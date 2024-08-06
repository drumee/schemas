DELIMITER $
DROP PROCEDURE IF EXISTS `ident_exists`$
CREATE PROCEDURE `ident_exists`(
  IN _key VARCHAR(128)
)
BEGIN
  SELECT id, ident, status FROM entity WHERE ident=_key 
  UNION
  SELECT id, ident, 'active' status FROM organisation WHERE ident=_key;
END$
DELIMITER ;