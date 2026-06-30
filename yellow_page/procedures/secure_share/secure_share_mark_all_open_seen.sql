DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_mark_all_open_seen`$
CREATE PROCEDURE `secure_share_mark_all_open_seen`(
  IN _creator_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  -- "Mark all as read" for share-open notifications: stamp creator_seen_at on
  -- every one of the caller's notify-on-open share-open events so they all drop
  -- out of the Unread feed and stay out after a reload (still shown under Unread
  -- OFF). Same read model + scoping as secure_share_mark_open_seen, but across
  -- all tokens/recipients. Mirrors the WHERE of secure_share_open_feed so exactly
  -- the rows the panel surfaces get marked.
  UPDATE secure_share_access_event e
  JOIN secure_share_token t ON t.id = e.token_id
  SET e.creator_seen_at = UNIX_TIMESTAMP()
  WHERE t.creator_id = _creator_id
    AND t.notify_on_open != 0
    AND (e.actor_id IS NULL OR e.actor_id != _creator_id);
END$

DELIMITER ;
