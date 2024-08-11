DELIMITER $

--  Since link with drumate contact book so it shoud be in drumate db to  avoid dynamic sql
DROP PROCEDURE IF EXISTS `dmz_get_share_member`$
DROP PROCEDURE IF EXISTS `dmz_get_share_member_next`$
-- CREATE PROCEDURE `dmz_get_share_member_next`(
--   IN _share_id  VARCHAR(50),
--   IN _page INT
-- )
-- BEGIN

--   DECLARE _range bigint;
--   DECLARE _offset bigint;
  
--     SELECT 
--       _page as `page`,
--       coalesce(de.id, c.entity,g.id ) as id,
--       g.id member_id,
--       g.email,
--       c.status,
--       IFNULL(c.surname,  IF(coalesce(c.firstname, c.lastname) IS NULL, 
--         IFNULL(ce.email,de.email) , CONCAT( IFNULL(c.firstname, '') ,' ',  IFNULL(c.lastname, '')))) as surname
--     FROM 
--       yp.map_share s
--     INNER JOIN yp.member_share g ON g.id = s.recipient_id 
--     LEFT JOIN yp.drumate de ON de.email = g.email 
--     LEFT JOIN contact_email ce  ON ce.email =  g.email AND ce.is_default = 1    
--     LEFT JOIN contact c  on ce.contact_id = c.id
--     WHERE s.share_id = _share_id
--     ORDER BY g.email ASC;

-- END$
DELIMITER ;

