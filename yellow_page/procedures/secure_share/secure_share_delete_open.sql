DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_delete_open`$
CREATE PROCEDURE `secure_share_delete_open`(
  IN _creator_id VARCHAR(16) CHARACTER SET ascii,
  IN _token_id VARCHAR(80),
  IN _recipient_email VARCHAR(512)
)
BEGIN
  -- The trash button for a share-open notification.
  -- secure_share_mark_open_seen is NOT touched and keeps meaning "read"; this is
  -- a new name, so no existing caller can be broken by it.
  --
  -- Scoping, group matching and the ''/NULL recipient collapse are lifted
  -- VERBATIM from secure_share_mark_open_seen, deliberately: the two must select
  -- exactly the same rows or trashing a notification would clear a different
  -- group than reading it did. In particular await_proc turns a JS null into '',
  -- so an anonymous open arrives as _recipient_email='' and only NULLIF + the
  -- NULL-safe <=> matches it -- a plain IS NULL branch silently matched nothing,
  -- which is the bug that made anonymous opens reappear on reload.
  --
  -- creator_seen_at is filled when still NULL, because deleting implies having
  -- dealt with it: otherwise a trashed row would vanish from the panel while
  -- still counting as unread.
  UPDATE secure_share_access_event e
  JOIN secure_share_token t ON t.id = e.token_id
  SET e.creator_deleted_at = UNIX_TIMESTAMP(),
      e.creator_seen_at    = IFNULL(e.creator_seen_at, UNIX_TIMESTAMP())
  WHERE t.creator_id = _creator_id
    AND e.token_id = _token_id
    AND NULLIF(e.recipient_email, '') <=> NULLIF(_recipient_email, '');

  SELECT 'ok' AS status, _token_id AS token_id;
END$

DELIMITER ;
