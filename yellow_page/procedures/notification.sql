DELIMITER $


-- ==============================================================
-- Add sharebox notification
-- ==============================================================
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



-- ==============================================================
-- Accept sharebox notification
-- ==============================================================
DROP PROCEDURE IF EXISTS `yp_notification_accept`$
CREATE PROCEDURE `yp_notification_accept`(
  IN _rid VARCHAR(16),
  IN _eid VARCHAR(16)
)
BEGIN
    DECLARE _ts INT(11) DEFAULT 0;
    SELECT UNIX_TIMESTAMP() INTO _ts;
    UPDATE notification 
    SET status= 'accept',utime=_ts
    WHERE resource_id=_rid AND entity_id=_eid;
    SELECT owner_id,resource_id,entity_id,message,permission,status, 
    CASE WHEN expiry_time = 0 THEN 0 ELSE ((expiry_time - UNIX_TIMESTAMP())/3600) END  as expiry_time
    FROM notification WHERE resource_id=_rid AND entity_id=_eid;

END $

-- ==============================================================
--  Refuse or remove sharebox notification
-- ==============================================================
DROP PROCEDURE IF EXISTS `yp_notification_remove`$
CREATE PROCEDURE `yp_notification_remove`(
  IN _rid VARCHAR(16),
  IN _eid VARCHAR(16)
)
BEGIN
  
  IF _eid != '' THEN
    DELETE FROM notification WHERE resource_id=_rid AND entity_id=_eid;
  ELSE
    DELETE FROM notification WHERE resource_id=_rid;
  END IF;
    
END $


-- ==============================================================
--  Sharebox notification count
-- ==============================================================
DROP PROCEDURE IF EXISTS `yp_notification_count`$
CREATE PROCEDURE `yp_notification_count`(
  IN _eid VARCHAR(16)
 )
BEGIN
    DECLARE _db_name VARCHAR(512);
    DECLARE _sys_id int(11);
    DECLARE _resource_id varchar(512);
   

    DROP TABLE IF EXISTS  _temp_notification;
    CREATE TEMPORARY TABLE `_temp_notification` (
        `sys_id` int(11) unsigned NOT NULL ,
        `owner_id` varchar(16) NOT NULL,
        `resource_id` varchar(16) NOT NULL,
        `db_name` varchar(512) NOT NULL,
        `vhost` varchar(512),
        `hub_id` varchar(16) NOT NULL,
        `user_filename` varchar(512)  NULL,
        `category`  varchar(16)  NULL,
        `is_checked` boolean default 0
        );
       
    INSERT INTO _temp_notification
    SELECT   
        n.sys_id,
        n.owner_id,
        n.resource_id,
        e.db_name,
        e.vhost,
        e.id,
        null,null,0
    FROM 
        notification n
        INNER JOIN yp.hub sb on sb.owner_id =n.owner_id
        INNER JOIN entity e on e.id = sb.id  AND  e.area='restricted' 
    WHERE
        n.status = 'receive' 
        AND entity_id = _eid
        AND (expiry_time = 0 OR expiry_time > UNIX_TIMESTAMP());
    
    SELECT sys_id, resource_id, db_name 
    FROM _temp_notification WHERE  user_filename is null limit 1 
    INTO _sys_id, _resource_id,_db_name; 

    
    WHILE _sys_id IS NOT NULL DO
        
        SET @sql = CONCAT(    
            'SELECT user_filename,category FROM ' ,
            _db_name ,'.media where id =',QUOTE( _resource_id),'  INTO @user_filename ,@category'            
        );
       
       PREPARE stmt FROM @sql ;
       EXECUTE stmt;
       DEALLOCATE PREPARE stmt;

       UPDATE _temp_notification SET
        user_filename = @user_filename, 
        category = @category,
        is_checked = 1
       WHERE sys_id =_sys_id;
       SELECT NULL INTO _sys_id ;
       SELECT sys_id,resource_id, db_name 
       FROM _temp_notification WHERE  is_checked = 0  limit 1 
       INTO _sys_id, _resource_id,_db_name; 
        
    END WHILE;

    DELETE FROM _temp_notification WHERE user_filename IS NULL;

    SELECT count(sys_id) count  FROM _temp_notification ; 
END $




-- ==============================================================
--  Sharebox notification list
-- ==============================================================
DROP PROCEDURE IF EXISTS `yp_notification_receive_list`$
CREATE PROCEDURE `yp_notification_receive_list`(
  IN _eid VARCHAR(16)
 )
BEGIN
    DECLARE _db_name VARCHAR(512);
    DECLARE _sys_id int(11);
    DECLARE _resource_id varchar(512);
   

    DROP TABLE IF EXISTS  _temp_notification;
    CREATE TEMPORARY TABLE `_temp_notification` (
        `sys_id` int(11) unsigned NOT NULL ,
        `owner_id` varchar(16) NOT NULL,
        `resource_id` varchar(16) NOT NULL,
        `db_name` varchar(512) NOT NULL,
        `vhost` varchar(512),
        `hub_id` varchar(16) NOT NULL,
        `user_filename` varchar(512)  NULL,
        `category`  varchar(16)  NULL,
        `is_checked` boolean default 0
        );
       
    INSERT INTO _temp_notification
    SELECT   
        n.sys_id,
        n.owner_id,
        n.resource_id,
        e.db_name,
        e.vhost,
        e.id,
        null,null,0
    FROM 
        notification n
        INNER JOIN yp.hub sb on sb.owner_id =n.owner_id
        INNER JOIN entity e on e.id = sb.id AND  e.area='restricted' 
    WHERE
        n.status = 'receive' 
        AND entity_id = _eid
        AND (expiry_time = 0 OR expiry_time > UNIX_TIMESTAMP());
    
    SELECT sys_id, resource_id, db_name 
    FROM _temp_notification WHERE  user_filename is null limit 1 
    INTO _sys_id, _resource_id,_db_name; 

    
    WHILE _sys_id IS NOT NULL DO
        
        SET @sql = CONCAT(    
            'SELECT user_filename,category FROM ' ,
            _db_name ,'.media where id =',QUOTE( _resource_id),'  INTO @user_filename ,@category'            
        );
       
       PREPARE stmt FROM @sql ;
       EXECUTE stmt;
       DEALLOCATE PREPARE stmt;

       UPDATE _temp_notification SET
        user_filename = @user_filename, 
        category = @category,
        is_checked = 1
       WHERE sys_id =_sys_id;
       SELECT NULL INTO _sys_id ;
       SELECT sys_id,resource_id, db_name 
       FROM _temp_notification WHERE  is_checked = 0  limit 1 
       INTO _sys_id, _resource_id,_db_name; 
        
    END WHILE;

    DELETE FROM _temp_notification WHERE user_filename IS NULL;

    SELECT 
        n.resource_id as nid,
        t.user_filename,
        t.category,
        n.owner_id as uid,
        t.hub_id,
        t.vhost,
        n.message,
        CASE 
            WHEN expiry_time = 0 THEN  NULL
            WHEN (expiry_time - UNIX_TIMESTAMP()) < 86400  THEN 0
            WHEN (expiry_time - UNIX_TIMESTAMP()) > 86400  THEN FLOOR((expiry_time - UNIX_TIMESTAMP())/86400)
        END days, 
        CASE 
            WHEN expiry_time = 0 THEN  NULL
            WHEN 
            (expiry_time - UNIX_TIMESTAMP()) > 0   THEN CEIL(MOD((expiry_time - UNIX_TIMESTAMP()),86400)/3600)  
            WHEN (expiry_time - UNIX_TIMESTAMP()) > 0  THEN 0
        END hours ,
        d.firstname,
        d.email
    FROM
    notification n 
    INNER JOIN _temp_notification t on t.sys_id = n.sys_id
    INNER JOIN drumate d on d.id = n.owner_id;
END $

DELIMITER ;

