DELIMITER $

-- =========================================================
-- p2p_export_messages
-- ONE direct conversation, oldest first, both sides, active only, within
-- [_start, _end] (NULL = open), with the author's name from yp.drumate.
-- _page >= 1: that page of 45; _page = 0: every message in one call (the
-- export is capped at 10k by p2p_export_count, and paging would copy the
-- whole conversation into the temp table once per page).
-- =========================================================
DROP PROCEDURE IF EXISTS `p2p_export_messages`$
CREATE PROCEDURE `p2p_export_messages`(
  IN _peer_id VARCHAR(16) CHARACTER SET ascii,
  IN _start INT(11),
  IN _end INT(11),
  IN _page INT(11)
)
BEGIN
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _peer_db VARCHAR(255);
  DECLARE _range INT DEFAULT 45;
  DECLARE _offset INT DEFAULT 0;
  DECLARE CONTINUE HANDLER FOR NOT FOUND BEGIN END;

  SET _offset = (GREATEST(IFNULL(_page, 1), 1) - 1) * _range;
  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;
  SELECT db_name FROM yp.entity WHERE id = _peer_id INTO _peer_db;

  DROP TEMPORARY TABLE IF EXISTS _p2p_x;
  CREATE TEMPORARY TABLE _p2p_x (
    message_id VARCHAR(16) CHARACTER SET ascii, author_id VARCHAR(16) CHARACTER SET ascii,
    message MEDIUMTEXT, thread_id VARCHAR(16) CHARACTER SET ascii, attachment LONGTEXT,
    ctime INT(11), metadata MEDIUMTEXT
  );
  -- The date window is applied while copying (idx_peer_ctime), not after.
  INSERT INTO _p2p_x SELECT message_id, author_id, message, thread_id, attachment, ctime, metadata
    FROM p2p_channel WHERE peer_id = _peer_id AND status = 'active'
      AND (_start IS NULL OR ctime >= _start) AND (_end IS NULL OR ctime <= _end);
  IF _peer_db IS NOT NULL AND EXISTS (SELECT 1 FROM information_schema.tables
      WHERE table_schema = _peer_db AND table_name = 'p2p_channel') THEN
    SET @_s = CONCAT("INSERT INTO _p2p_x SELECT message_id, author_id, message, thread_id, ",
      "attachment, ctime, metadata FROM `", _peer_db,
      "`.p2p_channel WHERE peer_id = ? AND status = 'active' ",
      "AND (? IS NULL OR ctime >= ?) AND (? IS NULL OR ctime <= ?)");
    PREPARE _st FROM @_s; EXECUTE _st USING _uid, _start, _start, _end, _end; DEALLOCATE PREPARE _st;
  END IF;

  IF IFNULL(_page, 1) = 0 THEN
    SET _offset = 0;
    SET _range = 2147483647;
  END IF;

  SELECT m.message_id, m.author_id, m.message, m.thread_id, m.attachment, m.ctime, m.metadata,
         IFNULL(d.firstname, '') AS firstname, IFNULL(d.lastname, '') AS lastname,
         IFNULL(d.fullname, '') AS fullname
    FROM _p2p_x m
    LEFT JOIN yp.drumate d ON d.id = m.author_id
    WHERE (_start IS NULL OR m.ctime >= _start) AND (_end IS NULL OR m.ctime <= _end)
    ORDER BY m.ctime ASC, m.message_id ASC
    LIMIT _offset, _range;
  DROP TEMPORARY TABLE IF EXISTS _p2p_x;
END$

DELIMITER ;
