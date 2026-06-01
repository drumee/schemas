DELIMITER $

DROP PROCEDURE IF EXISTS `p2p_list_messages`$
CREATE PROCEDURE `p2p_list_messages`(
  IN _in JSON
)
BEGIN
  DECLARE _uid       VARCHAR(16) CHARACTER SET ascii;
  DECLARE _peer_id   VARCHAR(16) CHARACTER SET ascii;
  DECLARE _page      TINYINT(4);
  DECLARE _peer_db   VARCHAR(255);
  DECLARE _range     BIGINT;
  DECLARE _offset    BIGINT;
  DECLARE _ref_ctime INT(11) UNSIGNED DEFAULT 0;
  DECLARE _peer_ref_ctime INT(11) UNSIGNED DEFAULT 0;
  DECLARE _max_ctime INT(11) UNSIGNED;

  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;
  SELECT JSON_UNQUOTE(JSON_EXTRACT(_in, "$.peer_id")) INTO _peer_id;
  SELECT JSON_UNQUOTE(JSON_EXTRACT(_in, "$.page"))    INTO _page;
  CALL pageToLimits(_page, _offset, _range);

  SELECT db_name FROM yp.entity WHERE id = _peer_id INTO _peer_db;

  -- My last-read cursor for this conversation
  SELECT ref_ctime FROM p2p_read WHERE peer_id = _peer_id AND uid = _uid INTO _ref_ctime;

  -- Peer's last-read cursor over MY messages. The peer advances their own
  -- cursor in THEIR DB (row peer_id = _uid, uid = _peer_id), so read it from
  -- there. Drives the Messenger-style "seen" avatar on my outgoing messages.
  IF _peer_db IS NOT NULL THEN
    SET @_peer_ref := NULL;
    SET @_sql = CONCAT(
      "SELECT ref_ctime INTO @_peer_ref FROM `", _peer_db,
      "`.p2p_read WHERE peer_id = ? AND uid = ? LIMIT 1"
    );
    PREPARE _stmt FROM @_sql;
    EXECUTE _stmt USING _uid, _peer_id;
    DEALLOCATE PREPARE _stmt;
    SET _peer_ref_ctime = IFNULL(@_peer_ref, 0);
  END IF;

  -- Build combined set from both sides of the conversation
  DROP TEMPORARY TABLE IF EXISTS `_p2p_msgs`;
  CREATE TEMPORARY TABLE `_p2p_msgs` (
    `sys_id`      INT(11) UNSIGNED NOT NULL,
    `peer_id`     VARCHAR(16) CHARACTER SET ascii NOT NULL,
    `author_id`   VARCHAR(16) CHARACTER SET ascii DEFAULT NULL,
    `message`     MEDIUMTEXT DEFAULT NULL,
    `message_id`  VARCHAR(16) CHARACTER SET ascii DEFAULT NULL,
    `thread_id`   VARCHAR(16) CHARACTER SET ascii DEFAULT NULL,
    `attachment`  LONGTEXT DEFAULT NULL,
    `is_forward`  TINYINT(1) DEFAULT 0,
    `mention_ids` LONGTEXT DEFAULT NULL,
    `status`      ENUM('draft','active','trashed') NOT NULL DEFAULT 'active',
    `ctime`       INT(11) NOT NULL,
    `metadata`    MEDIUMTEXT DEFAULT NULL
  );

  -- Messages I sent to peer (stored in my DB)
  INSERT INTO _p2p_msgs
  SELECT sys_id, peer_id, author_id, message, message_id, thread_id,
         attachment, is_forward, mention_ids, status, ctime, metadata
  FROM p2p_channel
  WHERE peer_id = _peer_id AND status != 'trashed';

  -- Messages peer sent to me (stored in peer's DB, peer_id = _uid there)
  IF _peer_db IS NOT NULL THEN
    SET @_sql = CONCAT(
      "INSERT INTO _p2p_msgs ",
      "SELECT sys_id, peer_id, author_id, message, message_id, thread_id, ",
      "attachment, is_forward, mention_ids, status, ctime, metadata ",
      "FROM `", _peer_db, "`.p2p_channel WHERE peer_id = ? AND status != 'trashed'"
    );
    PREPARE _stmt FROM @_sql;
    EXECUTE _stmt USING _uid;
    DEALLOCATE PREPARE _stmt;
  END IF;

  -- Acknowledge: advance my read cursor to the oldest message on this page
  SELECT ctime FROM _p2p_msgs ORDER BY ctime DESC LIMIT _offset, 1 INTO _max_ctime;
  IF _max_ctime IS NOT NULL THEN
    INSERT INTO p2p_read (peer_id, uid, ref_ctime, ctime)
    SELECT _peer_id, _uid, _max_ctime, UNIX_TIMESTAMP()
    ON DUPLICATE KEY UPDATE
      ref_ctime = GREATEST(ref_ctime, VALUES(ref_ctime)),
      ctime = VALUES(ctime);
  END IF;

  SELECT
    _page AS `page`,
    m.sys_id,
    m.peer_id,
    m.author_id,
    m.message,
    m.message_id,
    m.thread_id,
    m.is_forward,
    get_json_array(m.attachment, 0)                                    AS attachment_first,
    JSON_LENGTH(m.attachment)                                          AS attachment_count,
    CASE WHEN LTRIM(RTRIM(IFNULL(m.attachment, ''))) = '' THEN 0 ELSE 1 END AS is_attachment,
    m.mention_ids,
    m.status,
    m.ctime,
    m.metadata,
    CASE WHEN m.ctime > _ref_ctime AND m.author_id != _uid THEN 1 ELSE 0 END AS is_notify,
    CASE WHEN m.author_id = _uid OR m.ctime <= _ref_ctime THEN 1 ELSE 0 END  AS is_readed,
    CASE WHEN JSON_LENGTH(m.metadata, '$._seen_') >= JSON_LENGTH(m.metadata, '$._delivered_')
         THEN 1 ELSE 0 END                                             AS is_seen,
    IFNULL(JSON_VALUE(m.metadata, "$.message_type"), 'chat')          AS message_type,
    JSON_VALUE(m.metadata, "$.call_status")                           AS call_status,
    JSON_VALUE(m.metadata, "$.duration")                              AS call_duration,
    _peer_ref_ctime                                                   AS peer_ref_ctime
  FROM _p2p_msgs m
  ORDER BY m.ctime DESC
  LIMIT _offset, _range;

  DROP TEMPORARY TABLE IF EXISTS `_p2p_msgs`;

END $

DELIMITER ;