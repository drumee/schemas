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
    IFNULL(
      s.capabilities,
      CASE s.permission_level
        WHEN 'can_view'     THEN JSON_ARRAY()
        ELSE JSON_ARRAY(s.permission_level)
      END
    )                   AS capabilities,
    s.recipient_email,
    s.domain_restriction,
    s.allowed_emails,
    -- Recipients cut off this link individually — the sender's panel marks them
    -- as revoked in the link's access popup. Creator-scoped SP, sender-only data.
    s.denied_emails,
    -- Whether the link makes viewers identify themselves. Needed by the panel's
    -- access table to tell a "require email, any address" link apart from a
    -- genuinely public one: both have an empty allowed_emails, so without this
    -- the table labelled the former "Public link" even after a recipient had
    -- typed their address. Additive column -- existing callers select by name
    -- and are unaffected.
    s.require_email,
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
