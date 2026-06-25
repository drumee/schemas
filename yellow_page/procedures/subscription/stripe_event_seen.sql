DELIMITER $
DROP PROCEDURE IF EXISTS `stripe_event_seen`$
CREATE PROCEDURE `stripe_event_seen`(
  IN _event_id VARCHAR(64) CHARACTER SET ascii,
  IN _type VARCHAR(64) CHARACTER SET ascii
)
BEGIN
  DECLARE _rows INT DEFAULT 0;
  INSERT IGNORE INTO stripe_event (event_id, type, received_at)
  VALUES (_event_id, _type, UNIX_TIMESTAMP());
  SET _rows = ROW_COUNT();              -- 1 = first time inserted, 0 = already present
  SELECT IF(_rows = 1, 0, 1) AS duplicate;
END $
DELIMITER ;
