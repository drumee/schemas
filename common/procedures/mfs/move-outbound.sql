DELIMITER $

-- =========================================================
-- 
-- =========================================================
-- SHALL BE DEPRECATED
DROP PROCEDURE IF EXISTS `mfs_move_outbound`$
-- CREATE PROCEDURE `mfs_move_outbound`(
--   IN _rid VARCHAR(16),
--   IN _oid VARCHAR(16)
--  )
-- BEGIN
--   DECLARE _bound VARCHAR(16);
--   DECLARE _finished INTEGER DEFAULT 0;
--   DECLARE _db_name VARCHAR(50);
--   DECLARE _uid     VARCHAR(16);
    
--   SELECT '__Outbound__' FROM media WHERE id=_rid AND parent_path(id) LIKE CONCAT("/__Outbound__","%")  INTO _bound;  
    
--     IF _bound IS NOT NULL THEN 
--       BEGIN
--         DECLARE dbcursor CURSOR FOR  SELECT DISTINCT db_name , p.entity_id as uid
--         FROM 
--         media m
--         INNER JOIN permission p ON  p.resource_id=m.id 
--         INNER JOIN yp.hub b on b.owner_id = p.entity_id
--         INNER join yp.entity e on e.id = b.id AND e.area = 'restricted'
--         INNER JOIN media ch ON
--           CASE WHEN m.category = 'folder' 
--             THEN  REPLACE(CONCAT(parent_path(ch.id),ch.user_filename,'/'), '(',')')  regexp REPLACE(CONCAT(parent_path(m.id),m.user_filename,'/'), '(',')') 
--             ELSE m.id=ch.id
--             END = 1 
--         WHERE ch.id = _rid ;
--         DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;
--         OPEN dbcursor;
--           STARTLOOP: LOOP
--             FETCH dbcursor INTO _db_name,_uid ;
--             IF _finished = 1 THEN 
--               LEAVE STARTLOOP;
--             END IF;
--             CALL sbx_remove (_oid,  _rid, _uid );
--             CALL permission_revoke (_rid, null);
--             CALL yp.yp_notification_remove (_rid, null);
--           END LOOP STARTLOOP;   
--         CLOSE dbcursor;
--       END;
--     END IF;

-- END $


DELIMITER ;
