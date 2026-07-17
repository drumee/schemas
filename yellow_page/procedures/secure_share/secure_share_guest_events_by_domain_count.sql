DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_guest_events_by_domain_count`$
CREATE PROCEDURE `secure_share_guest_events_by_domain_count`(
  IN _domain_id INT(11) UNSIGNED,
  IN _from INT(11),
  IN _to INT(11),
  IN _search VARCHAR(512)
)
BEGIN
  SET _search = NULLIF(TRIM(IFNULL(_search, '')), '');

  -- Paired count for the guest-events paginator ("Showing X-Y of N").
  -- WHERE clause matches secure_share_guest_events_by_domain exactly.
  SELECT COUNT(*) AS total
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
         OR IFNULL(NULLIF(h.name, ''), h.hubname) LIKE CONCAT('%', _search, '%'));
END$

DELIMITER ;
