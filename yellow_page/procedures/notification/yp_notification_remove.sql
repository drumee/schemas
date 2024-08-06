DELIMITER $
DROP PROCEDURE IF EXISTS `yp_notification_remove`$
CREATE PROCEDURE `yp_notification_remove`(
  IN _rid VARCHAR(16),
  IN _eid VARCHAR(16)
)
BEGIN
  IF _eid != '' THEN
    DELETE FROM `notification` WHERE resource_id=_rid AND entity_id=_eid;
  ELSE
    DELETE FROM `notification` WHERE resource_id=_rid;
  END IF;
END $
DELIMITER ;

