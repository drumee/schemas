DELIMITER $

DROP PROCEDURE IF EXISTS `notification_rollup_delete`$
CREATE PROCEDURE `notification_rollup_delete`(
  IN _user_id VARCHAR(16),
  IN _category VARCHAR(16),
  IN _key_id VARCHAR(255)
)
BEGIN
  -- The trash button for a rollup row. Flags rather than DELETEs, because a
  -- row that is merely removed would be recreated by the very next badge
  -- refresh if the underlying conversation still had anything unread.
  --
  -- This is only half of the deletion. The caller must ALSO advance the
  -- underlying read pointer via notification_dismiss, which is what stops
  -- notification_center_next from generating the rollup again -- that call is
  -- already what today's trash button does, so the pairing costs nothing new.
  -- Without it the flag would be cleared again the moment newer activity
  -- arrived, since notification_rollup_put treats strictly newer ctime as a
  -- genuinely new notification.
  --
  -- INSERT ... ON DUPLICATE KEY rather than a bare UPDATE so that trashing a
  -- rollup the store has not captured yet still records the deletion instead
  -- of silently doing nothing.
  INSERT INTO notification_rollup
    (user_id, category, key_id, hub_id, payload, last_id, ctime, mtime, deleted)
  VALUES (_user_id, _category, _key_id, NULL, JSON_OBJECT(), NULL, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 1)
  ON DUPLICATE KEY UPDATE
    deleted = 1,
    mtime   = UNIX_TIMESTAMP();

  SELECT 'ok' AS status, _category AS category, _key_id AS key_id, 1 AS deleted;
END$

DELIMITER ;
