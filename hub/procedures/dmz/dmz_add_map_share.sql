DELIMITER $

DROP PROCEDURE IF EXISTS `dmz_add_map_share`$
DROP PROCEDURE IF EXISTS `dmz_add_map_share_next`$
-- CREATE PROCEDURE `dmz_add_map_share_next`(
--   IN _hub_id VARCHAR(50),
--   IN _recipient_id VARCHAR(16),
--   IN _share_id VARCHAR(16)
-- )
-- BEGIN
--   DECLARE _ts INT(11) DEFAULT 0;
--   DECLARE _is_sync int(4);

--     SELECT notify_at ,is_sync
--     FROM yp.map_share 
--     WHERE recipient_id = _recipient_id 
--     AND hub_id = _hub_id AND  share_id =_share_id INTO _ts,_is_sync;

--     INSERT INTO yp.map_share 
--       (
--         sys_id, hub_id,recipient_id,share_id
--       )
--     VALUES 
--       (
--       null, _hub_id, _recipient_id,_share_id
--     )
--     ON DUPLICATE KEY UPDATE notify_at=_ts ,is_sync =_is_sync; 

-- END$


DELIMITER ;




