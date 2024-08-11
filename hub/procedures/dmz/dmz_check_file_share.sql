DELIMITER $


-- =======================================================================
--
-- =======================================================================
DROP PROCEDURE IF EXISTS `dmz_check_file_share`$
-- CREATE PROCEDURE `dmz_check_file_share`(
--    IN _hub_id VARCHAR(16)
-- )
-- BEGIN

--   SELECT 
--     s.recipient_id public_id, 
--     m.id  AS nid,
--     s.id share_id
--   FROM media m
--     LEFT JOIN yp.filecap ff ON m.extension=ff.extension
--     INNER JOIN permission p ON m.id = p.resource_id
--     INNER JOIN yp.share s ON s.permission_id=p.sys_id
--     INNER JOIN yp.drumate d ON  s.uid=d.id 
--     INNER JOIN yp.hub h ON h.id=s.hub_id
--     -- LEFT JOIN yp.guest g on g.id =s.recipient_id
--   WHERE (s.hub_id = _hub_id)   AND s.mode ='file'  AND m.status = 'active';

-- END$



DELIMITER ;




