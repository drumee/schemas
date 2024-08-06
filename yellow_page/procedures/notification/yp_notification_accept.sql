DELIMITER $
DROP PROCEDURE IF EXISTS `yp_notification_accept`$
CREATE PROCEDURE `yp_notification_accept`(
  IN _rid VARCHAR(16),
  IN _eid VARCHAR(16)
)
BEGIN
  DECLARE _ts INT(11) DEFAULT 0;
  SELECT UNIX_TIMESTAMP() INTO _ts;
  UPDATE `notification` 
    SET status= 'accept',utime=_ts
  WHERE resource_id=_rid AND entity_id=_eid;

  SELECT 
    owner_id, 
    resource_id, 
    entity_id, 
    `message`, 
    permission,
    `status`, 
    CASE 
      WHEN expiry_time = 0 THEN 0 
      ELSE ((expiry_time - UNIX_TIMESTAMP())/3600) 
    END  as expiry_time
  FROM `notification` WHERE resource_id=_rid AND entity_id=_eid;
END $
DELIMITER ;

