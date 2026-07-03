DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_list_access_events`$
CREATE PROCEDURE `secure_share_list_access_events`(
  IN _hub_id     VARCHAR(16) CHARACTER SET ascii,
  IN _node_id    VARCHAR(16) CHARACTER SET ascii,
  IN _creator_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  SELECT
    e.sys_id          AS id,
    e.token_id,
    e.recipient_email,
    e.actor_id,
    e.entered_at,
    e.last_seen_at,
    (e.last_seen_at - e.entered_at) AS duration
  FROM  `secure_share_access_event` e
  JOIN  `secure_share_token` t ON t.id = e.token_id
  WHERE t.hub_id     = _hub_id
    AND t.node_id    = _node_id
    AND t.creator_id = _creator_id
    -- Show per-recipient access for GATED shares (require_email / legacy single
    -- recipient / password), AND for a PUBLIC link show any IDENTIFIED open — a
    -- signed-in recipient logs an actor_id / recipient_email (e.g. the workspace
    -- root "Manage access" public link). Truly anonymous opens (no actor_id AND no
    -- recipient_email) stay excluded — nothing to attribute.
    AND (t.require_email = 1 OR t.recipient_email IS NOT NULL OR t.password_hash IS NOT NULL
         OR e.actor_id IS NOT NULL OR e.recipient_email IS NOT NULL)
  ORDER BY e.last_seen_at DESC;
END$

DELIMITER ;
