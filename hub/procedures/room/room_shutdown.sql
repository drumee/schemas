
-- DELIMITER $

-- DROP PROCEDURE IF EXISTS `room_shutdown`$
-- DROP PROCEDURE IF EXISTS `room_shutdown_next`$
-- CREATE PROCEDURE `room_shutdown_next`(
--   IN _id VARCHAR(16)
-- )
-- BEGIN
--   DECLARE _count INTEGER DEFAULT 0;
--   CALL mfs_set_metadata(_id, JSON_OBJECT("room_status", "closed"), 0);
--   SELECT `type` FROM yp.room WHERE id=_id INTO @_type;
--   IF @_type != 'screen' THEN 
--     SELECT r.id FROM yp.room r INNER JOIN yp.entity e ON e.db_name  = DATABASE()
--       WHERE r.type = 'screen' INTO @_screen_id;    
--     DELETE FROM room_attendee;
--     DELETE r FROM yp.room r INNER JOIN yp.entity e WHERE e.db_name = DATABASE();
--     SELECT count(*) FROM media WHERE id=@_screen_id INTO _count;
--     IF _count = 0 THEN 
--       CALL permission_revoke(@_screen_id, '');
--     END IF;
--   ELSE
--     DELETE FROM room_attendee WHERE room_id=_id;
--     DELETE FROM yp.room WHERE id=_id;
--   END IF;
--   SELECT count(*) FROM media WHERE id=_id INTO _count;
--   IF _count = 0 THEN 
--     CALL permission_revoke(_id, '');
--   END IF;
--   DELETE FROM yp.room_endpoint WHERE room_id=_id;
-- END$


-- DROP PROCEDURE IF EXISTS `room_shutdown`$
-- CREATE PROCEDURE `room_shutdown`(
--   IN _id VARCHAR(16)
-- )
-- BEGIN
--   DECLARE _count INTEGER DEFAULT 0;
--   -- CALL mfs_set_metadata(_id, JSON_OBJECT("room_status", "closed"), 0);
--   -- SELECT count(*) FROM media WHERE id=_id INTO _count;
--   -- IF _count = 0 THEN 
--   --   CALL permission_revoke(_id, '');
--   -- END IF;
--   DELETE FROM room_attendee WHERE room_id=_id;
--   DELETE FROM yp.room WHERE id=_id;
-- END

-- DELIMITER ;

DROP PROCEDURE IF EXISTS `room_shutdown_next`;
DROP PROCEDURE IF EXISTS `room_shutdown`;