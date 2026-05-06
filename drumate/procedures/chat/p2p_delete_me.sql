DELIMITER $

DROP PROCEDURE IF EXISTS `p2p_delete_me`$
CREATE PROCEDURE `p2p_delete_me`(
  IN _in JSON
)
BEGIN
  DECLARE _uid        VARCHAR(16) CHARACTER SET ascii;
  DECLARE _message_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _peer_id    VARCHAR(16) CHARACTER SET ascii;
  DECLARE _max_ctime  INT(11) UNSIGNED;

  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;
  SELECT JSON_VALUE(_in, "$.message_id") INTO _message_id;

  -- Verify the message belongs to caller (only author can delete their own messages)
  SELECT peer_id FROM p2p_channel
  WHERE message_id = _message_id AND author_id = _uid
  INTO _peer_id;

  IF _peer_id IS NULL THEN
    SELECT JSON_OBJECT('SUCCESS', 0, 'ERROR', 'MESSAGE_NOT_FOUND_OR_NOT_AUTHOR') AS result;
  ELSE
    UPDATE p2p_channel SET status = 'trashed' WHERE message_id = _message_id;

    -- Refresh p2p_time to the next most recent active message
    SELECT ctime FROM p2p_channel
    WHERE peer_id = _peer_id AND status = 'active'
    ORDER BY ctime DESC LIMIT 1
    INTO _max_ctime;

    IF _max_ctime IS NOT NULL THEN
      UPDATE p2p_time SET ref_ctime = _max_ctime, ctime = _max_ctime
      WHERE peer_id = _peer_id;
    ELSE
      DELETE FROM p2p_time WHERE peer_id = _peer_id;
    END IF;

    SELECT JSON_OBJECT('SUCCESS', 1, 'message_id', _message_id) AS result;
  END IF;

END $

DELIMITER ;