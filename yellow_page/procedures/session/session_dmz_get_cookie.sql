DELIMITER $

DROP PROCEDURE IF EXISTS `dmz_session_get_cookies`$
-- DROP PROCEDURE IF EXISTS `session_dmz_get_cookie`$
-- CREATE PROCEDURE `session_dmz_get_cookie`(
--  IN _sid varchar(64),
--  IN _hub_id varchar(16)  
-- )
-- BEGIN
 
--   DECLARE _share_id VARCHAR(50);
--   DECLARE _db VARCHAR(500);

--    SELECT 
--        share_id,s.hub_id
--     FROM 
--     cookie_share cs
--     INNER JOIN share s  ON s.id = cs.share_id AND cs.hub_id = s.hub_id
--     WHERE cs.id = _sid AND  cs.hub_id = _hub_id INTO _share_id,_hub_id ;


--     SELECT db_name FROM entity WHERE id = _hub_id INTO _db;

--     SET @st = CONCAT('CALL ', _db ,'.dmz_show_link_content(?,?)');
--     PREPARE stamt FROM @st;
--     EXECUTE stamt USING _share_id, _sid;
--     DEALLOCATE PREPARE stamt; 
   

-- END $



DELIMITER ;