DELIMITER $
DROP PROCEDURE IF EXISTS `hub_update_title`$
CREATE PROCEDURE `hub_update_title`(
  IN _hub_id    VARCHAR(16),
  IN _hub_title VARCHAR(200)
)
BEGIN
  UPDATE entity SET headline = _hub_title WHERE id = _hub_id;
  SELECT * FROM entity WHERE id = _hub_id;
END $

DELIMITER ;
