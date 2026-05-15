DELIMITER $

DROP PROCEDURE IF EXISTS `p2p_delete_me`$
CREATE PROCEDURE `p2p_delete_me`(
  IN _in JSON
)
BEGIN
  DECLARE _uid        VARCHAR(16) CHARACTER SET ascii;
  DECLARE _message_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _peer_id    VARCHAR(16) CHARACTER SET ascii;
  DECLARE _peer_db    VARCHAR(255);
  DECLARE _max_ctime  INT(11) UNSIGNED;
  DECLARE _rows_found INT DEFAULT 0;

  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;
  SELECT JSON_VALUE(_in, "$.message_id") INTO _message_id;
  SELECT JSON_VALUE(_in, "$.peer_id")    INTO _peer_id;

  -- Case 1: I am the author (message stored in my DB)
  SELECT COUNT(1) FROM p2p_channel
  WHERE message_id = _message_id AND author_id = _uid
  INTO _rows_found;

  IF _rows_found > 0 THEN
    UPDATE p2p_channel SET status = 'trashed' WHERE message_id = _message_id;

    SELECT peer_id FROM p2p_channel WHERE message_id = _message_id INTO _peer_id;

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

  -- Case 2: I am the recipient (message stored in peer's DB)
  ELSEIF _peer_id IS NOT NULL THEN
    SELECT db_name FROM yp.entity WHERE id = _peer_id INTO _peer_db;
    IF _peer_db IS NOT NULL THEN
      SET @_sql = CONCAT(
        "UPDATE `", _peer_db, "`.p2p_channel SET status = 'trashed' ",
        "WHERE message_id = ? AND author_id = ? AND peer_id = ?"
      );
      PREPARE _stmt FROM @_sql;
      EXECUTE _stmt USING _message_id, _peer_id, _uid;
      DEALLOCATE PREPARE _stmt;
    END IF;
    SELECT JSON_OBJECT('SUCCESS', 1, 'message_id', _message_id) AS result;

  ELSE
    SELECT JSON_OBJECT('SUCCESS', 0, 'ERROR', 'MESSAGE_NOT_FOUND') AS result;
  END IF;

END $

DELIMITER ;
