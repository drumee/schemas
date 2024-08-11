DELIMITER $


DROP PROCEDURE IF EXISTS `dmz_check_password`$
-- CREATE PROCEDURE `dmz_check_password`(
--  IN _share_id VARCHAR(50),
--  IN _recipient_id VARCHAR(16),
--  IN _pw VARCHAR(2000),
--  IN _sid varchar(64) 
-- )
-- BEGIN
--   DECLARE _fingerprint varchar(128);
--   SELECT fingerprint FROM yp.share WHERE id =_share_id INTO _fingerprint;
--   -- SELECT _fingerprint ,sha2(_pw, 512) ;

--   UPDATE yp.cookie_share SET is_verified = 1 WHERE (_fingerprint = sha2(_pw, 512) OR  _fingerprint = _pw) 
--     AND id = _sid AND share_id = _share_id AND  recipient_id = _recipient_id;
--   CALL dmz_check_link(_share_id, _recipient_id,_sid);

-- END$


DELIMITER ;




