DELIMITER $

DROP PROCEDURE IF EXISTS `get_entity_settings`$
CREATE PROCEDURE `get_entity_settings`(
  IN _id    VARCHAR(120)
)
BEGIN
  SELECT id, settings FROM entity WHERE id=_id or ident=_id;
END$
DELIMITER ;