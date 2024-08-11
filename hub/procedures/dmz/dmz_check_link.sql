DELIMITER $


DROP PROCEDURE IF EXISTS `dmz_check_link`$
-- CREATE PROCEDURE `dmz_check_link`(
--   IN _share_id VARCHAR(50),
--   IN _recipient_id   VARCHAR(16),
--   IN _sid varchar(64)  
-- )
-- BEGIN
--   DECLARE _is_verified INT DEFAULT 0;
--   DECLARE _is_valid INT DEFAULT 0;
--   DECLARE _is_active INT DEFAULT 0;
--   DECLARE _is_password INT DEFAULT 0;
--   DECLARE _email VARCHAR(500);
--   DECLARE _hub_id  VARCHAR(16);
--   DECLARE _name VARCHAR(5000);
--   DECLARE _sender  VARCHAR(5000);
--   DECLARE _permission  TINYINT(4) unsigned DEFAULT 0;
--   DECLARE _is_public   TINYINT(4) unsigned DEFAULT 0; 


--   SELECT  is_verified FROM yp.cookie_share 
--     WHERE id = _sid  AND share_id = _share_id  AND recipient_id = _recipient_id  
--   INTO  _is_verified;

  
--   IF _recipient_id IN ('') THEN 
--    SELECT NULL INTO  _recipient_id;
--   END IF;
 
--   SELECT 1 FROM yp.share s  WHERE id = _share_id  INTO _is_valid;  

--   SELECT 1 FROM yp.share s  WHERE id = _share_id AND recipient_id = _recipient_id  INTO _is_public;  

--   SELECT 0 FROM yp.share s  
--   INNER JOIN yp.map_share ms ON ms.hub_id = s.hub_id  AND ms.share_id =s.id
--   WHERE s.id = _share_id AND ms.recipient_id = _recipient_id  INTO _is_public; 

--   IF NOT _is_verified THEN
--     SELECT 1, permission FROM permission 
--       WHERE resource_id = _share_id  AND entity_id = _recipient_id 
--     INTO  _is_verified, _permission;
--   END IF; 

--   IF _is_public = 1  THEN 
--     SELECT 
    
--       s.hub_id,
--       CASE 
--         WHEN s.fingerprint IS NULL THEN 0 
--         ELSE 1
--       END  is_password,
--       CASE 
--         WHEN user_expiry ('*', m.id) = 0 OR user_expiry ('*', m.id) > UNIX_TIMESTAMP() THEN 1 
--         ELSE 0 
--         END is_active,
--       CASE 
--         WHEN s.fingerprint IS NULL THEN 1 
--         ELSE  _is_verified 
--       END is_verified,h.name, d.fullname, p.permission privilege
--     FROM media m
--       INNER JOIN permission p ON m.id = p.resource_id
--       INNER JOIN yp.share s ON s.permission_id=p.sys_id
--       INNER JOIN yp.drumate d ON  s.uid=d.id 
--       INNER JOIN yp.hub h ON h.id=s.hub_id
--       WHERE (s.id = _share_id)  AND m.status = 'active'
--       INTO _hub_id, _is_password,_is_active, _is_verified,
--         _name,_sender,_permission ;
   
--    ELSE 

--     SELECT 
--       g.email, s.hub_id,
--       CASE 
--         WHEN s.fingerprint IS NULL THEN 0 
--         ELSE 1
--       END is_password,
--       CASE 
--         WHEN user_expiry('*', m.id) = 0 OR user_expiry('*', m.id) > UNIX_TIMESTAMP() THEN 1 
--         ELSE 0 
--         END is_active,
--       CASE 
--         WHEN s.fingerprint IS NULL THEN 1 
--         ELSE  _is_verified 
--       END _is_verified, h.name, d.fullname, p.permission privilege
--     FROM media m
--       INNER JOIN permission p ON m.id = p.resource_id
--       INNER JOIN yp.share s ON s.permission_id=p.sys_id
--       INNER JOIN yp.map_share ms ON ms.hub_id = s.hub_id AND s.id = ms.share_id
--       INNER JOIN yp.member_share g on g.id =ms.recipient_id 
--       INNER JOIN yp.drumate d ON  s.uid=d.id 
--       INNER JOIN yp.hub h ON h.id=s.hub_id
--     WHERE (s.id = _share_id )  
--       AND  ms.recipient_id = _recipient_id AND m.status = 'active'
--       INTO  _email,_hub_id, _is_password,_is_active, _is_verified,
--       _name,_sender,_permission ;

--   END IF;

--   UPDATE yp.cookie_share SET is_verified = _is_verified WHERE id = _sid AND share_id = _share_id;

--   SELECT _hub_id hub_id,_email email, _is_password is_password, _is_public is_public,
--     _is_verified is_verified,_is_active is_active, _is_valid is_valid, 
--     _name name ,_sender sender , _permission privilege;

-- END$

 


DELIMITER ;


