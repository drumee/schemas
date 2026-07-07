DELIMITER $

DROP PROCEDURE IF EXISTS `member_list_stats`$
CREATE PROCEDURE `member_list_stats`(
  IN _org_id VARCHAR(16)
)
BEGIN
  DECLARE _dom_id INT;

  SELECT domain_id FROM organisation WHERE id = _org_id INTO _dom_id;

  SELECT
    COUNT(DISTINCT p.uid) AS total_members,
    -- Admins = members carrying the admin permission bit (16), matching
    -- hub_member_stats (`permission & 16`) and the role labels. The old
    -- `privilege > 1` over-counted every write-capable member as an admin.
    SUM(CASE WHEN p.privilege & 16 THEN 1 ELSE 0 END) AS admins,
    SUM(CASE WHEN COALESCE(d.connected, '0') = '0' AND e.status = 'active' THEN 1 ELSE 0 END) AS pending_invites,
    (
      -- External guests = distinct external people who opened a secure share
      -- created by a member of this org. Mirrors secure_share_guest_events_by_domain
      -- (the "External Guest Activity" audit table): scope by the share creator's
      -- domain, exclude the org's own members (anonymous + other-domain accounts
      -- are kept). Email-gated shares ("require external guest email") record the
      -- guest's email in recipient_email; COUNT(DISTINCT) drops NULLs so ungated
      -- anonymous opens don't inflate the headcount. This replaces the legacy
      -- dmz_token source, which the secure-share flow never writes to.
      SELECT COUNT(DISTINCT ae.recipient_email)
      FROM secure_share_access_event ae
      INNER JOIN secure_share_token st ON st.id = ae.token_id
      INNER JOIN drumate owner ON owner.id = st.creator_id AND owner.domain_id = _dom_id
      LEFT JOIN drumate viewer ON viewer.id = ae.actor_id
      WHERE ae.actor_id IS NULL
         OR viewer.domain_id IS NULL
         OR viewer.domain_id != _dom_id
    ) AS external_guests
  FROM privilege p
  INNER JOIN organisation o ON p.domain_id = o.domain_id
  INNER JOIN drumate d ON p.uid = d.id
  INNER JOIN entity e ON d.id = e.id
  WHERE
    o.id = _org_id AND
    p.domain_id = _dom_id AND
    COALESCE(JSON_VALUE(d.profile, '$.category'), '') <> 'system' AND
    e.status != 'archived';
END $

DELIMITER ;
