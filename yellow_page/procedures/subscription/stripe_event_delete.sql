DELIMITER $

DROP PROCEDURE IF EXISTS `stripe_event_delete`$
CREATE PROCEDURE `stripe_event_delete`(
  IN _event_id VARCHAR(64) CHARACTER SET ascii
)
BEGIN
  -- Undo a stripe_event_seen row so a FAILED webhook can be re-processed on
  -- Stripe's retry. The webhook marks an event "seen" (for idempotency) BEFORE
  -- processing; if processing then throws, leaving the seen row in place would
  -- make every Stripe retry hit the duplicate guard and skip — silently losing
  -- the event (e.g. a cancellation downgrade that never lands). On error the
  -- handler calls this + returns a non-2xx so Stripe retries against a clean
  -- slate.
  DELETE FROM stripe_event WHERE event_id = _event_id;
END $

DELIMITER ;
