DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_respond_to_access_request`$
CREATE PROCEDURE `secure_share_respond_to_access_request`(
  IN _request_id    VARCHAR(16),
  IN _responder_id  VARCHAR(16),
  IN _action        VARCHAR(8),
  IN _granted_level VARCHAR(64)
)
BEGIN
  DECLARE _creator_id    VARCHAR(16) CHARACTER SET ascii;
  DECLARE _req_status    VARCHAR(10);
  DECLARE _active_socket VARCHAR(32);

  SELECT r.creator_id, r.status
  INTO   _creator_id, _req_status
  FROM   `secure_share_access_request` r
  WHERE  r.id = _request_id
  LIMIT  1;

  IF _creator_id IS NULL THEN
    SELECT NULL AS id, 'NOT_FOUND' AS error;
  ELSEIF _req_status != 'pending' THEN
    SELECT NULL AS id, 'ALREADY_RESPONDED' AS error;
  ELSEIF _creator_id != _responder_id THEN
    SELECT NULL AS id, 'FORBIDDEN' AS error;
  ELSE
    UPDATE `secure_share_access_request`
    SET
      status        = IF(_action = 'approve', 'approved', 'denied'),
      granted_level = IF(_action = 'approve', _granted_level, NULL),
      responded_at  = UNIX_TIMESTAMP()
    WHERE id = _request_id;

    -- Retrieve active_socket_id from the share token for real-time guest notification
    SELECT t.active_socket_id INTO _active_socket
    FROM   `secure_share_access_request` r
    JOIN   `secure_share_token` t ON t.id = r.token_id
    WHERE  r.id = _request_id
    LIMIT  1;

    SELECT r.id, r.token_id, r.hub_id, r.node_id, r.creator_id,
           r.requester_email, r.requested_level, r.granted_level,
           r.status, r.responded_at,
           _active_socket AS guest_socket_id
    FROM   `secure_share_access_request` r
    WHERE  r.id = _request_id;
  END IF;
END$

DELIMITER ;
