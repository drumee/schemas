DELIMITER $

DROP PROCEDURE IF EXISTS `yp_add_guest`$
CREATE PROCEDURE `yp_add_guest`(
  IN _email         VARCHAR(500),
  IN _firstname     VARCHAR(200),
  IN _lastname      VARCHAR(200),
  IN _expiry_time   INT(11)         
)
BEGIN
  DECLARE _ts INT(11) DEFAULT 0; 
  DECLARE _ctime INT(11) ; 
  DECLARE _id           VARCHAR(16) ; 
  SELECT UNIX_TIMESTAMP() ,UNIX_TIMESTAMP() INTO _ts,_ctime;
  SELECT yp.uniqueId() INTO _id;
  SELECT id , ctime FROM guest WHERE email = _email INTO _id ,_ctime;
  REPLACE INTO guest (sys_id,id,email,firstname,lastname,expiry_time,ctime,utime ) SELECT  NULL, _id,_email,_firstname,_lastname,_expiry_time,_ctime,_ts ;
  SELECT * FROM guest WHERE id = _id;
END$

DELIMITER ;