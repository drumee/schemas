DELIMITER $

DROP PROCEDURE IF EXISTS `session_dmz_check_cookie`$
-- CREATE PROCEDURE `session_dmz_check_cookie`(
--  IN _share_id VARCHAR(50),
--  IN _sid varchar(64),
--  IN _hub_id varchar(16),    
--  IN _recipient_id varchar(16)
-- )
-- BEGIN
--   DECLARE _is_verified INT(4) DEFAULT 0;
--   DECLARE _is_valid INT(4) DEFAULT 0;


--   SELECT 1, hub_id FROM share WHERE id = _share_id  -- AND hub_id =_hub_id 
--     INTO _is_valid, _hub_id ;
--   IF _is_valid = 1 THEN  
--     SELECT  is_verified FROM cookie_share WHERE id = _sid AND share_id=_share_id 
--     AND hub_id = _hub_id  AND _recipient_id = _recipient_id
--     INTO  _is_verified;
--     INSERT INTO cookie_share(sys_id, id,share_id,hub_id ,recipient_id )
--     SELECT NULL, _sid,_share_id,_hub_id,_recipient_id
--     ON DUPLICATE KEY UPDATE is_verified =_is_verified ; 
--     SELECT * FROM cookie_share WHERE id = _sid  AND hub_id = _hub_id AND is_verified;
--   END IF;
-- END $


DELIMITER ;