DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_list_open_notifications`$
CREATE PROCEDURE `secure_share_list_open_notifications`(
  IN _creator_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  -- Recent opens across all of this creator's secure shares, for the activity
  -- notification panel. Deduped to the latest open per (share, recipient) so a
  -- recipient re-opening does not spam the panel; only shares with notify_on_open
  -- enabled; the creator's own opens are excluded; capped to the last 7 days.
  SELECT
    MAX(e.sys_id)       AS id,
    e.token_id,
    e.hub_id,
    e.node_id,
    e.recipient_email,
    MAX(e.last_seen_at) AS last_seen_at
  FROM  `secure_share_access_event` e
  JOIN  `secure_share_token` t ON t.id = e.token_id
  WHERE t.creator_id     = _creator_id
    AND t.notify_on_open != 0
    AND (e.actor_id IS NULL OR e.actor_id != _creator_id)
    AND e.last_seen_at >= (UNIX_TIMESTAMP() - 604800)
  GROUP BY e.token_id, e.hub_id, e.node_id, e.recipient_email
  ORDER BY last_seen_at DESC
  LIMIT 50;
END$

DELIMITER ;
