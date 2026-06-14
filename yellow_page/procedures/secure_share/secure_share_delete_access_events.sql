DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_delete_access_events`$
CREATE PROCEDURE `secure_share_delete_access_events`(
  IN _hub_id     VARCHAR(16) CHARACTER SET ascii,
  IN _node_id    VARCHAR(16) CHARACTER SET ascii,
  IN _creator_id VARCHAR(16) CHARACTER SET ascii,
  IN _email      VARCHAR(512)
)
BEGIN
  DELETE e
  FROM  `secure_share_access_event` e
  JOIN  `secure_share_token` t ON t.id = e.token_id
  WHERE t.hub_id     = _hub_id
    AND t.node_id    = _node_id
    AND t.creator_id = _creator_id
    AND e.recipient_email = _email;
END$

DELIMITER ;
