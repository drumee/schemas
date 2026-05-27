DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_access_log`$
CREATE PROCEDURE `secure_share_access_log`(
  IN _token    VARCHAR(80),
  IN _actor_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  DECLARE _hub_id     VARCHAR(16) CHARACTER SET ascii;
  DECLARE _node_id    VARCHAR(16) CHARACTER SET ascii;
  DECLARE _creator_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _email      VARCHAR(512);

  SELECT hub_id, node_id, creator_id, recipient_email
  INTO   _hub_id, _node_id, _creator_id, _email
  FROM   `secure_share_token`
  WHERE  id = _token
  LIMIT  1;

  IF _hub_id IS NOT NULL THEN
    UPDATE `secure_share_token`
    SET    access_count  = access_count + 1,
           last_accessed = UNIX_TIMESTAMP()
    WHERE  id = _token;

    SELECT
      _hub_id     AS hub_id,
      _node_id    AS node_id,
      _creator_id AS creator_id,
      _email      AS recipient_email,
      _actor_id   AS actor_id
    ;
  END IF;
END$

DELIMITER ;
