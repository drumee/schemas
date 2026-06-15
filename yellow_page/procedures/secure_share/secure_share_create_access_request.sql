DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_create_access_request`$
CREATE PROCEDURE `secure_share_create_access_request`(
  IN _args JSON
)
BEGIN
  DECLARE _token_id        VARCHAR(80);
  DECLARE _requester_email VARCHAR(512);
  DECLARE _requested_level VARCHAR(64);
  DECLARE _message         TEXT;
  DECLARE _hub_id          VARCHAR(16) CHARACTER SET ascii;
  DECLARE _node_id         VARCHAR(16) CHARACTER SET ascii;
  DECLARE _creator_id      VARCHAR(16) CHARACTER SET ascii;
  DECLARE _revoked_at      INT(11) DEFAULT NULL;
  DECLARE _expiry_time     INT(11) DEFAULT 0;
  DECLARE _existing_id     VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _new_id          VARCHAR(16) CHARACTER SET ascii;

  SELECT JSON_VALUE(_args, '$.token_id')        INTO _token_id;
  SELECT LOWER(TRIM(JSON_VALUE(_args, '$.requester_email'))) INTO _requester_email;
  SELECT JSON_VALUE(_args, '$.requested_level') INTO _requested_level;
  SELECT JSON_VALUE(_args, '$.message')         INTO _message;

  -- Validate token exists and is active (not revoked or expired)
  SELECT hub_id, node_id, creator_id, revoked_at, expiry_time
  INTO   _hub_id, _node_id, _creator_id, _revoked_at, _expiry_time
  FROM   `secure_share_token`
  WHERE  id = _token_id
  LIMIT  1;

  IF _hub_id IS NULL
    OR _revoked_at IS NOT NULL
    OR (_expiry_time > 0 AND UNIX_TIMESTAMP() > _expiry_time) THEN
    SELECT NULL AS id, 'INVALID_TOKEN' AS status;
  ELSE
    -- Idempotent: return existing pending request for same email + token
    SELECT id INTO _existing_id
    FROM   `secure_share_access_request`
    WHERE  token_id        = _token_id
      AND  requester_email = _requester_email
      AND  status          = 'pending'
    LIMIT  1;

    IF _existing_id IS NOT NULL THEN
      SELECT id, token_id, hub_id, node_id, creator_id,
             requester_email, requested_level, message, status, ctime
      FROM   `secure_share_access_request`
      WHERE  id = _existing_id;
    ELSE
      SET _new_id = LOWER(LEFT(REPLACE(UUID(), '-', ''), 16));

      INSERT INTO `secure_share_access_request`
        (id, token_id, hub_id, node_id, creator_id,
         requester_email, requested_level, message, status, ctime)
      VALUES
        (_new_id, _token_id, _hub_id, _node_id, _creator_id,
         _requester_email, _requested_level, _message, 'pending', UNIX_TIMESTAMP());

      SELECT id, token_id, hub_id, node_id, creator_id,
             requester_email, requested_level, message, status, ctime
      FROM   `secure_share_access_request`
      WHERE  id = _new_id;
    END IF;
  END IF;
END$

DELIMITER ;
