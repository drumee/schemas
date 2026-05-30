DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_delete`$
CREATE PROCEDURE `secure_share_delete`(
  IN _token      VARCHAR(80),
  IN _creator_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  -- Only hard-delete tokens that are already revoked or expired; never delete active ones.
  DELETE FROM `secure_share_token`
  WHERE  id         = _token
    AND  creator_id = _creator_id
    AND  (
      revoked_at IS NOT NULL
      OR (expiry_time > 0 AND UNIX_TIMESTAMP() > expiry_time)
    );

  SELECT ROW_COUNT() AS deleted;
END$

DELIMITER ;
