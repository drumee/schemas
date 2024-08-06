DELIMITER $

DROP PROCEDURE IF EXISTS `yp_add_share_guest`$
CREATE PROCEDURE `yp_add_share_guest`(
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
  INSERT IGNORE INTO share_guest (hub_id,email,permission,expiry_time) VALUES(_hub_id,_email,_permission,_tx)
      ON DUPLICATE KEY UPDATE permission=@perm, expiry_time = _tx ;
  SELECT * FROM share_guest WHERE hub_id = _hub_id AND email=_email;
END$

DELIMITER ;