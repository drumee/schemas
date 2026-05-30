DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_revoke`$
CREATE PROCEDURE `secure_share_revoke`(
  IN _token      VARCHAR(80),
  IN _creator_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  UPDATE `secure_share_token`
  SET    revoked_at = UNIX_TIMESTAMP()
  WHERE  id         = _token
    AND  creator_id = _creator_id
    AND  revoked_at IS NULL;

  -- Only return the row when the UPDATE actually set revoked_at (i.e. owned by this creator).
  -- An empty result tells the caller the revoke did not happen.
  SELECT
    s.sys_id,
    s.id,
    s.hub_id,
    s.node_id,
    s.creator_id,
    s.recipient_email,
    s.revoked_at,
    s.access_count,
    s.last_accessed,
    s.active_socket_id
  FROM `secure_share_token` s
  WHERE  s.id         = _token
    AND  s.creator_id = _creator_id
    AND  s.revoked_at IS NOT NULL;
END$

DELIMITER ;
