DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_list_requests`$
CREATE PROCEDURE `secure_share_list_requests`(
  IN _creator_id VARCHAR(16)
)
BEGIN
  -- Pending access requests addressed to a share creator, newest first.
  -- Backs the sender's notification-panel entries (Figma 62). The workspace
  -- name comes from yp.hub; the per-node (folder) name is resolved by the
  -- caller if needed.
  SELECT
    r.id              AS request_id,
    r.token_id,
    r.hub_id,
    r.node_id,
    r.requester_email,
    r.requested_level,
    r.message,
    r.status,
    r.ctime,
    h.name            AS workspace_name
  FROM `secure_share_access_request` r
  LEFT JOIN `hub` h ON h.id = r.hub_id
  WHERE r.creator_id = _creator_id
    AND r.status     = 'pending'
  ORDER BY r.ctime DESC;
END$

DELIMITER ;
