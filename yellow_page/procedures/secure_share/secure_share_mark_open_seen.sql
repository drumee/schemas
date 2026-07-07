DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_mark_open_seen`$
CREATE PROCEDURE `secure_share_mark_open_seen`(
  IN _creator_id VARCHAR(16) CHARACTER SET ascii,
  IN _token_id VARCHAR(80),
  IN _recipient_email VARCHAR(512)
)
BEGIN
  -- Stamp the creator's "seen" time on a share-open notification group so it drops
  -- out of the unread feed (Unread ON) yet still shows under Unread OFF. Scoped to
  -- the caller's own shares (t.creator_id = _creator_id) so one creator can never
  -- mark another creator's events. Marks the whole (token, recipient) group; a
  -- later re-open (newer last_seen_at) naturally resurfaces it as unread.
  UPDATE secure_share_access_event e
  JOIN secure_share_token t ON t.id = e.token_id
  SET e.creator_seen_at = UNIX_TIMESTAMP()
  WHERE t.creator_id = _creator_id
    AND e.token_id = _token_id
    AND (e.recipient_email = _recipient_email
         OR (_recipient_email IS NULL AND e.recipient_email IS NULL));
END$

DELIMITER ;
