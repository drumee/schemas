DELIMITER $

DROP PROCEDURE IF EXISTS `yp_get_share_guest`$
CREATE PROCEDURE `yp_get_share_guest`(
    IN _email      VARCHAR(512)
)
BEGIN
  SELECT * FROM share_guest WHERE email = _email;
END $


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

-- =========================================================
-- Removes guest 
-- =========================================================
DROP PROCEDURE IF EXISTS `yp_remove_guest`$
CREATE PROCEDURE `yp_remove_guest`(
  IN _key          VARCHAR(200)
 )
BEGIN
  DELETE FROM guest WHERE (id = _key OR email = _key) ;
END$



-- =========================================================
-- Deletes all expired guest.
-- =========================================================
DROP PROCEDURE IF EXISTS `yp_delete_expired_guest`$
CREATE PROCEDURE `yp_delete_expired_guest`()
BEGIN
  DELETE FROM guest WHERE (expiry_time <> 0 AND expiry_time < UNIX_TIMESTAMP());
END$


-- =========================================================
-- get_external_share
-- =========================================================
DROP PROCEDURE IF EXISTS `get_external_share`$
CREATE PROCEDURE `get_external_share`(
     IN _share_id       VARCHAR(16)
)
BEGIN
  SELECT 
    -- n.owner_id AS oid,
    d.firstname AS firstname,
    d.lastname AS lastname, 
    n.resource_id  AS nid,
    s.id AS hub_id,
    n.message,
    n.permission,
    n.expiry_time
  FROM
    notification n
    INNER JOIN drumate d ON d.id= n.owner_id
    INNER JOIN share_box s ON s.owner_id = n.owner_id
    INNER JOIN guest g ON g.id = n.entity_id
  WHERE  
    n.share_id = _share_id AND 
    (n.expiry_time = 0 OR n.expiry_time > UNIX_TIMESTAMP());
END $




DELIMITER ;