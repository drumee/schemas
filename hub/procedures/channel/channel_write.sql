DELIMITER $
DROP PROCEDURE IF EXISTS `channel_write`$
CREATE PROCEDURE `channel_write`(
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _message_id VARCHAR(16) CHARACTER SET ascii,
  IN _message MEDIUMTEXT,
  IN _thread_id VARCHAR(16) CHARACTER SET ascii,
  IN _attachment LONGTEXT,
  IN _is_forward TINYINT(1),
  IN _mention_ids JSON
)
BEGIN
  DECLARE _ts INT UNSIGNED;
  DECLARE _member_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _done INT DEFAULT 0;
  DECLARE _delivered JSON DEFAULT JSON_OBJECT();
  DECLARE _seen JSON DEFAULT JSON_OBJECT();
  DECLARE _metadata JSON;
  DECLARE cur_members CURSOR FOR
    SELECT d.id
    FROM permission p
    INNER JOIN yp.drumate d ON p.entity_id = d.id
    WHERE p.resource_id = '*';
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _done = 1;
  SELECT UNIX_TIMESTAMP() INTO _ts;
  -- Build _delivered_ map from all authenticated hub members
  OPEN cur_members;
  read_loop: LOOP
    FETCH cur_members INTO _member_id;
    IF _done = 1 THEN LEAVE read_loop; END IF;
    SET _delivered = JSON_SET(_delivered, CONCAT('$.', _member_id), _ts);
  END LOOP;
  CLOSE cur_members;
  -- Author has already seen their own message
  SET _seen = JSON_SET(_seen, CONCAT('$.', _uid), _ts);
  SET _metadata = JSON_OBJECT('_delivered_', _delivered, '_seen_', _seen);
  INSERT INTO channel (
    author_id, message, message_id,
    thread_id, attachment, is_forward,
    mention_ids, status, ctime, metadata
  ) VALUES (
    _uid, _message, _message_id,
    _thread_id, _attachment, IFNULL(_is_forward, 0),
    _mention_ids, 'active', _ts, _metadata
  );
  SELECT
    c.sys_id,
    c.author_id,
    c.message,
    c.message_id,
    c.thread_id,
    c.is_forward,
    c.mention_ids,
    c.attachment,
    CASE WHEN LTRIM(RTRIM(c.attachment)) = '' OR c.attachment IS NULL THEN 0 ELSE 1 END is_attachment,
    c.status,
    c.ctime,
    c.metadata,
    COALESCE(d.firstname, du.name, '') firstname,
    COALESCE(d.lastname, '') lastname,
    COALESCE(CONCAT(d.firstname, ' ', d.lastname), du.name, '') fullname,
    0 is_notify,
    1 is_readed
  FROM channel c
  LEFT JOIN yp.drumate d ON c.author_id = d.id
  LEFT JOIN yp.dmz_user du ON c.author_id = du.id
  WHERE c.message_id = _message_id;
END$
DELIMITER ;