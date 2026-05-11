DELIMITER $

DROP PROCEDURE IF EXISTS `get_security_signals`$
CREATE PROCEDURE `get_security_signals`(
  IN _domain_id INT(11) UNSIGNED,
  IN _active_window INT(11)
)
BEGIN
  -- Org-wide inputs to the audit-logs Security Score formula.
  -- _active_window: seconds back from now to count a member as "active"
  -- (caller passes 90 days; configurable so we don't bake the policy here).
  DECLARE _active_threshold INT(11);
  SET _active_threshold = UNIX_TIMESTAMP() - _active_window;

  SELECT
    (SELECT COUNT(*) FROM drumate d
       WHERE d.domain_id = _domain_id) AS total_members,

    (SELECT COUNT(*) FROM drumate d
       WHERE d.domain_id = _domain_id
         AND d.otp IS NOT NULL
         AND d.otp <> '0'
         AND d.otp <> '') AS mfa_members,

    (SELECT COUNT(DISTINCT s.uid) FROM socket s
       INNER JOIN drumate d ON d.id = s.uid
       WHERE d.domain_id = _domain_id
         AND s.mtime >= _active_threshold) AS active_members,

    (SELECT COUNT(*) FROM entity e
       WHERE e.dom_id = _domain_id
         AND e.type = 'hub'
         AND e.status = 'active') AS total_hubs,

    -- External exposure: public share-box roots owned by org members plus
    -- non-expired guest invites into org hubs. share_box has UNIQUE(owner_id)
    -- so it's "members with a public root", not raw link count.
    (
      (SELECT COUNT(*) FROM share_box sb
         INNER JOIN drumate d ON d.id = sb.owner_id
         WHERE d.domain_id = _domain_id)
      +
      (SELECT COUNT(*) FROM share_guest sg
         INNER JOIN entity e ON e.id = sg.hub_id
         WHERE e.dom_id = _domain_id
           AND e.type = 'hub'
           AND e.status = 'active'
           AND (sg.expiry_time = 0 OR sg.expiry_time > UNIX_TIMESTAMP()))
    ) AS active_shares;
END$

DELIMITER ;
