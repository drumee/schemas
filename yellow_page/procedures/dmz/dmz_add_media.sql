

DELIMITER $

DROP PROCEDURE IF EXISTS `dmz_add_media`$
CREATE PROCEDURE `dmz_add_media`(
  IN _id      VARCHAR(16) CHARACTER SET ascii,
  IN _hub_id   VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  REPLACE INTO dmz_media (id, hub_id, `name`) 
    SELECT  _id, _hub_id, '';
  SELECT * FROM dmz_media WHERE id = _id;
END$

DELIMITER ;