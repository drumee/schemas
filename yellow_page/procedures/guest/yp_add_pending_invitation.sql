DELIMITER $

DROP PROCEDURE IF EXISTS `yp_add_pending_invitation`$
CREATE PROCEDURE `yp_add_pending_invitation`(
  IN _hub_id VARCHAR(16),
  IN _expiry_time INT(11),
  IN _permission TINYINT(4),
  IN _email      VARCHAR(512)
)
BEGIN
  DECLARE _ts INT(11) DEFAULT 0;
  DECLARE _tx INT(11) DEFAULT 0;

  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT IF(IFNULL(_expiry_time, 0) = 0, 0,
    UNIX_TIMESTAMP(TIMESTAMPADD(HOUR,_expiry_time, FROM_UNIXTIME(_ts)))) INTO _tx;
  INSERT INTO pending_invitation (hub_id,email,permission,expiry_time,created_at)
    VALUES(_hub_id,_email,_permission,_tx,_ts)
    ON DUPLICATE KEY UPDATE permission=_permission, expiry_time=_tx;
  SELECT * FROM pending_invitation WHERE hub_id = _hub_id AND email=_email;
END$

DELIMITER ;
