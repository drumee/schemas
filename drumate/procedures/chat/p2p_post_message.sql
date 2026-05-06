DELIMITER $

DROP PROCEDURE IF EXISTS `p2p_post_message`$
CREATE PROCEDURE `p2p_post_message`(
  IN _in JSON,
  IN _message TEXT
)
BEGIN
  DECLARE _uid                VARCHAR(16) CHARACTER SET ascii;
  DECLARE _peer_id            VARCHAR(16) CHARACTER SET ascii;
  DECLARE _author_id          VARCHAR(16) CHARACTER SET ascii;
  DECLARE _message_id         VARCHAR(16) CHARACTER SET ascii;
  DECLARE _thread_id          VARCHAR(16) CHARACTER SET ascii;
  DECLARE _forward_message_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _attachment         JSON;
  DECLARE _metadata           JSON;
  DECLARE _mention_ids        JSON;
  DECLARE _ctime              INT(11) UNSIGNED;
  DECLARE _ref_sys_id         INT(11) UNSIGNED;
  DECLARE _peer_db            VARCHAR(255);
  DECLARE _is_duplicate       INT DEFAULT 0;

  DECLARE _db_err JSON;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
    SELECT JSON_OBJECT('MSG', @text, 'STATE', @sqlstate) INTO _db_err;
    SELECT JSON_OBJECT('SUCCESS', 0, 'ERROR', _db_err) INTO _db_err;
    SELECT _db_err;
  END;

  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;

  SELECT JSON_VALUE(_in, "$.peer_id")           INTO _peer_id;
  SELECT JSON_VALUE(_in, "$.author_id")          INTO _author_id;
  SELECT JSON_VALUE(_in, "$.message_id")         INTO _message_id;
  SELECT JSON_VALUE(_in, "$.thread_id")          INTO _thread_id;
  SELECT JSON_VALUE(_in, "$.forward_message_id") INTO _forward_message_id;
  SELECT JSON_QUERY(_in, "$.attachment")         INTO _attachment;
  SELECT JSON_QUERY(_in, "$.metadata")           INTO _metadata;
  SELECT JSON_QUERY(_in, "$.mention_ids")        INTO _mention_ids;

  SELECT 1 FROM p2p_channel WHERE message_id = _message_id INTO _is_duplicate;
  SELECT UNIX_TIMESTAMP() INTO _ctime;

  IF _message = '' THEN
    SELECT NULL INTO _message;
  END IF;

  INSERT INTO p2p_channel
    (message_id, peer_id, author_id, message, thread_id, ctime, attachment, mention_ids, metadata)
  SELECT
    _message_id, _peer_id, _author_id, _message, _thread_id, _ctime, _attachment, _mention_ids, _metadata
  ON DUPLICATE KEY UPDATE message_id = _message_id;

  UPDATE p2p_channel
  SET metadata = JSON_MERGE(
    IFNULL(metadata, '{}'),
    JSON_OBJECT('_seen_',      JSON_OBJECT(_author_id, _ctime)),
    JSON_OBJECT('_delivered_', JSON_OBJECT(_author_id, _ctime))
  )
  WHERE message_id = _message_id AND _is_duplicate = 0;

  IF _forward_message_id IS NOT NULL THEN
    UPDATE p2p_channel
    SET is_forward = 1,
        metadata = JSON_MERGE(
          IFNULL(metadata, '{}'),
          JSON_OBJECT('forward_message_id', _forward_message_id)
        )
    WHERE message_id = _message_id AND _is_duplicate = 0;
  END IF;

  SELECT sys_id FROM p2p_channel WHERE message_id = _message_id INTO _ref_sys_id;

  -- Update sender's p2p_time: last message preview + attachment/metadata for conversation list
  INSERT INTO p2p_time (peer_id, ref_ctime, message, attachment, metadata, ctime)
  SELECT _peer_id, _ctime, _message, _attachment, _metadata, _ctime
  ON DUPLICATE KEY UPDATE
    ref_ctime = _ctime, message = _message,
    attachment = _attachment, metadata = _metadata, ctime = _ctime;

  -- Cross-DB: update receiver's p2p_time so their conversation list stays current
  SELECT db_name FROM yp.entity WHERE id = _peer_id INTO _peer_db;
  IF _peer_db IS NOT NULL THEN
    SET @_sql = CONCAT(
      "INSERT INTO `", _peer_db, "`.p2p_time (peer_id, ref_ctime, message, attachment, metadata, ctime) ",
      "SELECT ?, ?, ?, ?, ?, ? ",
      "ON DUPLICATE KEY UPDATE ref_ctime = VALUES(ref_ctime), message = VALUES(message), ",
      "attachment = VALUES(attachment), metadata = VALUES(metadata), ctime = VALUES(ctime)"
    );
    PREPARE _stmt FROM @_sql;
    EXECUTE _stmt USING _uid, _ctime, _message, _attachment, _metadata, _ctime;
    DEALLOCATE PREPARE _stmt;
  END IF;

  SELECT
    sys_id,
    peer_id,
    author_id,
    message,
    message_id,
    thread_id,
    is_forward,
    attachment,
    mention_ids,
    status,
    ctime,
    metadata,
    1 AS is_readed,
    0 AS is_seen,
    IFNULL(NULLIF(read_json_object(metadata, "message_type"), ''), 'chat') AS message_type,
    read_json_object(metadata, "call_status") AS call_status,
    read_json_object(metadata, "duration") AS call_duration
  FROM p2p_channel WHERE message_id = _message_id;

END $

DELIMITER ;