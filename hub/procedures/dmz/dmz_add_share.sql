DELIMITER $

DROP PROCEDURE IF EXISTS `dmz_add_share`$
DROP PROCEDURE IF EXISTS `dmz_add_share_next`$
-- CREATE PROCEDURE `dmz_add_share_next`(
--   IN _share_id VARCHAR(50),
--   IN _perm_id int(11) unsigned,
--   IN _uid VARCHAR(16),
--   IN _hub_id VARCHAR(16),
--   IN _pass VARCHAR(16),
--   IN _sid varchar(64),
--   IN _recipient_id  VARCHAR(16),
--   IN _mode VARCHAR(30) 
-- )
-- BEGIN

--   IF _pass IN ('') THEN 
--    SELECT NULL INTO  _pass;
--   END IF;


--   INSERT INTO  yp.share 
--     (
--       sys_id, id,permission_id,uid,hub_id,metadata, fingerprint, recipient_id,mode
--     )
--   VALUES 
--     (
--       null, _share_id, _perm_id, _uid, _hub_id, null, _pass,_recipient_id,_mode
--     )ON DUPLICATE KEY 
--     UPDATE fingerprint=_pass, permission_id=_perm_id, recipient_id=_recipient_id ; 

--     CALL dmz_show_link_content(_share_id,_sid,_recipient_id );

-- END$



DELIMITER ;




