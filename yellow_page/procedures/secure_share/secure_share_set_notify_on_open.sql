DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_set_notify_on_open`$
CREATE PROCEDURE `secure_share_set_notify_on_open`(
  IN _token          VARCHAR(80),
  IN _creator_id     VARCHAR(16) CHARACTER SET ascii,
  IN _notify_on_open TINYINT UNSIGNED
)
BEGIN
  -- Flip the sender's "notify me when someone opens this" preference on ONE of
  -- their own links, after the link has been created. notify_on_open was
  -- writable only by secure_share_create, so the panel's toggle could not
  -- persist once the link existed: the token stayed at 1 and the sender kept
  -- receiving open notifications (real-time secure_share_opened plus the
  -- share_open feed row) even with the toggle visibly off.
  --
  -- Scoped to creator_id like secure_share_revoke, so nobody can change a link
  -- they do not own. notify_on_open is the ONLY writable column here: the
  -- capability set, expiry, email gate and password stay create-time only.
  --
  -- Anything that is not an explicit 0 stores 1, matching secure_share_create's
  -- own rule. The caller already coerces to 0/1, so this only decides the
  -- last-resort case (e.g. a NULL arg): it keeps notifications ON rather than
  -- silently switching off a sender who never asked for that, and the caller
  -- compares the returned value against what it requested.
  UPDATE `secure_share_token`
  SET    notify_on_open = IF(_notify_on_open = 0, 0, 1)
  WHERE  id             = _token
    AND  creator_id     = _creator_id;

  -- Only returns a row when the token exists AND belongs to this creator, so an
  -- empty result tells the caller the change did not happen — same contract as
  -- secure_share_revoke. Deliberately identical for "no such token" and "not
  -- yours" so the response cannot be used to probe for other people's tokens.
  SELECT id, notify_on_open
  FROM   `secure_share_token`
  WHERE  id         = _token
    AND  creator_id = _creator_id;
END$

DELIMITER ;
