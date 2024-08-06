DELIMITER $

DROP PROCEDURE IF EXISTS `entity_touch`$
CREATE PROCEDURE `entity_touch`(
  IN _key VARBINARY(128)
)
BEGIN
  UPDATE entity SET mtime=UNIX_TIMESTAMP() WHERE id=_key OR ident=_key;
  SELECT id, ident, mtime, settings FROM entity WHERE id=_key OR ident=_key;
END$

DELIMITER ;