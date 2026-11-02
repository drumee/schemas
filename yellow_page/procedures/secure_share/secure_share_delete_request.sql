DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_delete_request`$
CREATE PROCEDURE `secure_share_delete_request`(
  IN _creator_id VARCHAR(16) CHARACTER SET ascii,
  IN _request_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  -- The trash button for a pending access request (sender's notification
  -- panel). Only hides it from secure_share_list_requests: the status stays
  -- 'pending', so nothing changes for the requester and the request can still
  -- be answered. Scoped to the caller's own requests.
  UPDATE `secure_share_access_request`
  SET    creator_deleted_at = IFNULL(creator_deleted_at, UNIX_TIMESTAMP())
  WHERE  id         = _request_id
    AND  creator_id = _creator_id;

  SELECT 'ok' AS status, _request_id AS request_id, ROW_COUNT() AS deleted;
END$

DELIMITER ;
