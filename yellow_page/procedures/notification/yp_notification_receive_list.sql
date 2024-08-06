DELIMITER $
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
        (expiry_time - UNIX_TIMESTAMP()) > 0 THEN CEIL(MOD((expiry_time - UNIX_TIMESTAMP()),86400)/3600)  
      WHEN (expiry_time - UNIX_TIMESTAMP()) > 0  THEN 0
    END hours,
    d.firstname,
    d.email
  FROM
  notification n 
  INNER JOIN _temp_notification t on t.sys_id = n.sys_id
  INNER JOIN drumate d on d.id = n.owner_id;
END $

DELIMITER ;

