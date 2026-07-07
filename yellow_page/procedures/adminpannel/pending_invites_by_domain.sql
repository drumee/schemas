DELIMITER $

DROP PROCEDURE IF EXISTS `pending_invites_by_domain`$
CREATE PROCEDURE `pending_invites_by_domain`(
  IN _dom_id INT,
  IN _hub_id VARCHAR(16)
)
BEGIN
  -- Backing list for the admin-console "Pending Invites" stat-card popup:
  -- people invited to a workspace by email who have not joined yet (still parked
  -- in pending_invitation, keyed hub_id+email). Scoped to the caller's domain,
  -- optionally narrowed to a single workspace (_hub_id; '' or NULL = whole org),
  -- excluding expired invites. Workspace name resolved like member_list_workspaces.
  SELECT
    pi.email,
    pi.hub_id,
    pi.permission,
    pi.expiry_time,
    pi.created_at,
    IFNULL(IFNULL(e.ident, h.name), h.hubname) AS workspace_name
  FROM pending_invitation pi
  INNER JOIN entity e ON e.id = pi.hub_id
  LEFT JOIN hub h ON h.id = pi.hub_id
  WHERE e.dom_id = _dom_id
    AND e.type = 'hub'
    AND e.status = 'active'
    AND (_hub_id IS NULL OR _hub_id = '' OR pi.hub_id = _hub_id)
    AND (pi.expiry_time = 0 OR pi.expiry_time > UNIX_TIMESTAMP())
  ORDER BY pi.created_at DESC;
END $

DELIMITER ;
