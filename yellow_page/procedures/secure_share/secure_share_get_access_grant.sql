DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_get_access_grant`$
CREATE PROCEDURE `secure_share_get_access_grant`(
  IN _token_id VARCHAR(80),
  IN _email    VARCHAR(512)
)
BEGIN
  SELECT granted_level, token_id, requester_email
  FROM   `secure_share_access_request`
  WHERE  token_id        = _token_id
    AND  requester_email = LOWER(TRIM(_email))
    AND  status          = 'approved'
  ORDER BY responded_at DESC;
END$

DELIMITER ;
