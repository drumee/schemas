-- =========================================================
-- entity_register
-- =========================================================

DELIMITER $

DROP PROCEDURE IF EXISTS `entity_update_settings`$
CREATE PROCEDURE `entity_update_settings`(
  IN _id    VARCHAR(16),
  IN _data  JSON
)
BEGIN
  UPDATE entity SET settings=_data WHERE id=_id ; 
  SELECT id, settings FROM entity WHERE id=_id ; 
END $

DELIMITER ;

