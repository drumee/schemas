DELIMITER $
DROP PROCEDURE IF EXISTS `stripe_event_processed`$
CREATE PROCEDURE `stripe_event_processed`(
  IN _event_id VARCHAR(64) CHARACTER SET ascii
)
BEGIN
  UPDATE stripe_event SET processed_at = UNIX_TIMESTAMP() WHERE event_id = _event_id;
END $
DELIMITER ;
