DELIMITER $

DROP PROCEDURE IF EXISTS `dmz_get_map_share`$
DROP PROCEDURE IF EXISTS `dmz_get_map_share_next`$
-- CREATE PROCEDURE `dmz_get_map_share_next`(
--   IN _page INT,
--   IN _share_id VARCHAR(50)
-- )
-- BEGIN
--   DECLARE _hub_id VARCHAR(50); 
--   DECLARE _range bigint;
--   DECLARE _offset bigint;

--     SELECT id  FROM yp.entity WHERE db_name = DATABASE() INTO _hub_id;

--     SELECT 
--       _page as `page`,
--       g.id member_id,
--       g.email
--     FROM 
--       yp.map_share s
--     INNER JOIN yp.member_share g ON g.id = s.recipient_id 
--     WHERE s.hub_id = _hub_id AND s.share_id = _share_id
--     ORDER BY email ASC;

-- END$



DELIMITER ;




