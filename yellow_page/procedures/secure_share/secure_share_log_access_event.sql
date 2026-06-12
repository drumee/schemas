DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_log_access_event`$
CREATE PROCEDURE `secure_share_log_access_event`(
  IN _token     VARCHAR(80),
  IN _email     VARCHAR(512),
  IN _actor_id  VARCHAR(16) CHARACTER SET ascii,
  IN _socket_id VARCHAR(32)
)
BEGIN
  DECLARE _hub_id   VARCHAR(16) CHARACTER SET ascii;
  DECLARE _node_id  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _tok_mail VARCHAR(512);
  DECLARE _mail     VARCHAR(512);
  DECLARE _now      INT DEFAULT 0;
  DECLARE _existing INT DEFAULT 0;

  SET _now = UNIX_TIMESTAMP();

  SELECT hub_id, node_id, recipient_email
  INTO   _hub_id, _node_id, _tok_mail
  FROM   `secure_share_token`
  WHERE  id = _token
  LIMIT  1;

  SET _mail = NULLIF(TRIM(IFNULL(_email, '')), '');
  IF _mail IS NULL THEN
    SET _mail = _tok_mail;
  END IF;

  IF _hub_id IS NOT NULL AND _socket_id IS NOT NULL AND _socket_id != '' THEN
    SELECT sys_id
    INTO   _existing
    FROM   `secure_share_access_event`
    WHERE  token_id = _token AND socket_id = _socket_id
    ORDER BY sys_id DESC
    LIMIT  1;

    IF _existing > 0 THEN
      UPDATE `secure_share_access_event`
      SET    last_seen_at = _now,
             recipient_email = IFNULL(_mail, recipient_email),
             actor_id        = IFNULL(_actor_id, actor_id)
      WHERE  sys_id = _existing;
    ELSE
      INSERT INTO `secure_share_access_event`
        (token_id, hub_id, node_id, recipient_email, actor_id, socket_id, entered_at, last_seen_at)
      VALUES
        (_token, _hub_id, _node_id, _mail, _actor_id, _socket_id, _now, _now);
    END IF;
  END IF;
END$

DELIMITER ;
