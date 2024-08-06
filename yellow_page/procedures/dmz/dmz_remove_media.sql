DELIMITER $

DROP PROCEDURE IF EXISTS `dmz_remove_media`$
CREATE PROCEDURE `dmz_remove_media`(
  IN _id      VARCHAR(16) CHARACTER SET ascii
 
)
BEGIN
 SELECT * FROM dmz_media WHERE id = _id;
 DELETE FROM dmz_media WHERE id = _id;
END$

DROP PROCEDURE IF EXISTS `dmz_revoke`$
CREATE PROCEDURE `dmz_revoke`(
  IN _hub_id    VARCHAR(16) CHARACTER SET ascii,
  IN _node_id   VARCHAR(16) CHARACTER SET ascii,
  IN _guest_id  VARCHAR(64) CHARACTER SET ascii
)

BEGIN
 IF _guest_id IN ('') THEN 
   SELECT NULL INTO  _guest_id;
 END IF;

 SELECT * FROM dmz_token 
 WHERE hub_id=_hub_id AND node_id=_node_id AND guest_id=_guest_id;

 DELETE FROM dmz_token 
 WHERE hub_id=_hub_id AND node_id=_node_id AND guest_id=IFNULL(_guest_id,guest_id);
END$




DELIMITER ;