DELIMITER $
DROP PROCEDURE IF EXISTS `hub_update_visibility`$
CREATE PROCEDURE `hub_update_visibility`(
  IN _hub_id        VARCHAR(16),
  IN _visibility    VARCHAR(50)
)
BEGIN
  UPDATE entity SET area = _visibility WHERE id = _hub_id;
  SELECT * FROM entity WHERE id = _hub_id;
END $
DELIMITER ;
