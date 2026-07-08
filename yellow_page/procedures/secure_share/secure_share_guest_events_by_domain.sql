DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_guest_events_by_domain`$
CREATE PROCEDURE `secure_share_guest_events_by_domain`(
  IN _domain_id INT(11) UNSIGNED,
  IN _from INT(11),
  IN _to INT(11),
  IN _page VARCHAR(32),
  IN _search VARCHAR(512)
)
BEGIN
  DECLARE _range BIGINT;
  DECLARE _offset BIGINT;

  CALL pageToLimits(_page, _offset, _range);

  SET _search = NULLIF(TRIM(IFNULL(_search, '')), '');

  -- Org-wide external-guest opens on secure shares: every access event on a
  -- token created by a member of the domain, EXCLUDING opens by the domain's
  -- own members (anonymous guests and other-domain accounts are kept).
  -- Public (ungated) links are included on purpose — is_protected flags them.
  SELECT
    e.sys_id AS id,
    e.token_id,
    t.hub_id,
    t.node_id,
    e.recipient_email,
    e.actor_id,
    e.entered_at,
    e.last_seen_at,
    GREATEST(0, e.last_seen_at - e.entered_at) AS duration,
    IF(t.require_email = 1 OR t.password_hash IS NOT NULL
       OR t.recipient_email IS NOT NULL, 1, 0) AS is_protected,
    t.permission_level,
    owner.fullname AS owner_name,
    IFNULL(NULLIF(h.name, ''), h.hubname) AS workspace_name
  FROM secure_share_access_event e
  INNER JOIN secure_share_token t ON t.id = e.token_id
  INNER JOIN drumate owner
    ON owner.id = t.creator_id AND owner.domain_id = _domain_id
  LEFT JOIN drumate viewer ON viewer.id = e.actor_id
  LEFT JOIN hub h ON h.id = t.hub_id
  WHERE (e.actor_id IS NULL
         OR viewer.domain_id IS NULL
         OR viewer.domain_id != _domain_id)
    AND (_from = 0 OR e.entered_at >= _from)
    AND (_to = 0 OR e.entered_at <= _to)
    AND (_search IS NULL
         OR e.recipient_email LIKE CONCAT('%', _search, '%')
         OR owner.fullname LIKE CONCAT('%', _search, '%')
         OR owner.email LIKE CONCAT('%', _search, '%')
         OR IFNULL(NULLIF(h.name, ''), h.hubname) LIKE CONCAT('%', _search, '%'))
  ORDER BY e.entered_at DESC
  LIMIT _offset, _range;
END$

DELIMITER ;
