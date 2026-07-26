DELIMITER $
DROP PROCEDURE IF EXISTS `stripe_event_seen`$
CREATE PROCEDURE `stripe_event_seen`(
  IN _event_id VARCHAR(64) CHARACTER SET ascii,
  IN _type VARCHAR(64) CHARACTER SET ascii
)
BEGIN
  DECLARE _rows INT DEFAULT 0;
  DECLARE _claimed INT DEFAULT 0;
  -- How long one delivery may hold an unfinished row before another delivery of
  -- the same event is allowed to take it over. Comfortably longer than a reducer
  -- run (a few Stripe reads plus an email), far shorter than Stripe's retry gap.
  DECLARE _lock_window INT DEFAULT 120;

  INSERT IGNORE INTO stripe_event (event_id, type, received_at)
  VALUES (_event_id, _type, UNIX_TIMESTAMP());
  SET _rows = ROW_COUNT();              -- 1 = first time inserted, 0 = already present

  IF _rows = 1 THEN
    SELECT 0 AS duplicate;
  ELSE
    -- The row already exists, which is NOT the same as the event having been
    -- handled. It counts as a duplicate only once the reducer finished
    -- (processed_at set), or while another delivery is still working inside the
    -- lock window. A row left unprocessed past that window belongs to a run that
    -- died before it could clean itself up, so this delivery reclaims it. Waving
    -- such an event through would answer every Stripe retry with ok and drop the
    -- event permanently -- an invoice.paid lost that way never bumps period_end.
    UPDATE stripe_event
       SET received_at = UNIX_TIMESTAMP(),
           type = _type
     WHERE event_id = _event_id
       AND processed_at IS NULL
       AND received_at <= UNIX_TIMESTAMP() - _lock_window;
    SET _claimed = ROW_COUNT();         -- 1 = this delivery won the takeover
    SELECT IF(_claimed = 1, 0, 1) AS duplicate;
  END IF;
END $
DELIMITER ;
