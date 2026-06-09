DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_list`$
CREATE PROCEDURE `secure_share_list`(
  IN _hub_id     VARCHAR(16) CHARACTER SET ascii,
  IN _node_id    VARCHAR(16) CHARACTER SET ascii,
  IN _creator_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  SELECT
    s.sys_id,
    s.id,
    s.hub_id,
    s.node_id,
    s.creator_id,
    s.permission_level,
    s.recipient_email,
    s.domain_restriction,
    s.allowed_emails,
    s.expiry_time,
    s.revoked_at,
    s.access_count,
    s.last_accessed,
    s.ctime,
    CASE
      WHEN s.revoked_at IS NOT NULL                               THEN 'revoked'
      WHEN s.expiry_time > 0 AND UNIX_TIMESTAMP() > s.expiry_time THEN 'expired'
      ELSE 'active'
    END AS `status`
  FROM  `secure_share_token` s
  WHERE  s.hub_id     = _hub_id
    AND  s.node_id    = _node_id
    AND  s.creator_id = _creator_id
  ORDER BY s.ctime DESC;
END$

DELIMITER ;
