DELIMITER $
DROP PROCEDURE IF EXISTS `yp_notification_next`$
CREATE PROCEDURE `yp_notification_next`(
  IN _oid VARCHAR(16),  
  IN _rid VARCHAR(16),
  IN _uid VARCHAR(16),
  IN _share_id VARCHAR(50),
  IN _expiry_time INT(11),
  IN _permission TINYINT(4),
  IN _msg mediumtext
)
BEGIN
  DECLARE _ts INT(11) DEFAULT 0;
  DECLARE _tx INT(11) DEFAULT 0;
  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT cast(_permission as unsigned) INTO @perm;

  SELECT IF(IFNULL(_expiry_time, 0) = 0, 0,
    UNIX_TIMESTAMP(TIMESTAMPADD(HOUR,_expiry_time, FROM_UNIXTIME(_ts)))) INTO _tx;

  INSERT IGNORE INTO notification
    VALUES(null,_share_id,_oid,_rid, _uid, _msg, _tx,  @perm,'receive',_ts, _ts )
    ON DUPLICATE KEY UPDATE permission=@perm, utime=_ts, expiry_time = _tx,message=_msg,
    status =  CASE WHEN status = 'accept' THEN  'change' ELSE 'receive' END,sys_id=last_insert_id(sys_id)  ;
  SELECT * FROM  notification WHERE sys_id= LAST_INSERT_ID();
END $
DELIMITER ;

