DELIMITER $


DROP PROCEDURE IF EXISTS `dmz_remove_map_share`$
DROP PROCEDURE IF EXISTS `dmz_remove_map_share_next`$
-- CREATE PROCEDURE `dmz_remove_map_share_next`(
--   IN _hub_id VARCHAR(50),
--   IN _recipient_id VARCHAR(16),
--   IN _share_id VARCHAR(16) 
-- )
-- BEGIN

--   DELETE FROM yp.map_share 
--   WHERE recipient_id = _recipient_id 
--     AND share_id = _share_id
--       AND hub_id = _hub_id;
-- END$


DELIMITER ;




