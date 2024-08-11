DELIMITER $

DROP PROCEDURE IF EXISTS `dmz_update_notify_next`$
-- CREATE PROCEDURE `dmz_update_notify_next`(
--   IN _share_id VARCHAR(50), 
--   IN _recipient_id   VARCHAR(16)
-- )
-- BEGIN
--   DECLARE _ts INT(11);
--   UPDATE yp.map_share s SET notify_at = UNIX_TIMESTAMP()
--   WHERE recipient_id = _recipient_id 
--   AND share_id = _share_id; 

-- END$

DELIMITER ;




