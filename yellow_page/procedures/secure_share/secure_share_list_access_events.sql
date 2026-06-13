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
  ORDER BY e.last_seen_at DESC;
END$

DELIMITER ;
