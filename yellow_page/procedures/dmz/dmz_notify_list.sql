DELIMITER $


DROP PROCEDURE IF EXISTS `dmz_notify_list`$
-- CREATE PROCEDURE `dmz_notify_list`(
--   IN _token VARCHAR(150),
--   IN _flag   VARCHAR(50)
-- )
-- BEGIN
--   DECLARE _ts INT(11);
  
--   SELECT UNIX_TIMESTAMP()INTO _ts;
--   SELECT UNIX_TIMESTAMP()-43200 INTO _ts WHERE _flag = 'new' ;
  

--   SELECT 
--     t.hub_id,
--     t.guest_id recipient_id,
--     t.guest_id,
--     u.email,
--     t.notify_at
--   FROM 
--     dmz_user u
--   INNER JOIN dmz_token t ON u.id = t.guest_id
--   WHERE t.id = _token AND s.notify_at <= _ts ;
-- END$

DELIMITER ;




