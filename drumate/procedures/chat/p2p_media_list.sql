DELIMITER $

-- =========================================================
-- p2p_media_list
-- One page of a DIRECT conversation's photos / videos / files (60 per
-- page) or link messages (30 per page), newest first. Same scope as
-- p2p_media_stats: the viewer's p2p_channel (peer_id = _peer_id) plus the
-- peer's (peer_id = viewer), since a DM message is stored only in its
-- sender's DB. Attachments are resolved in their own hub (the sender's
-- wicket), active nodes only; media rows carry that hub_id so the client
-- can address the thumbnail.
-- =========================================================
DROP PROCEDURE IF EXISTS `p2p_media_list`$
CREATE PROCEDURE `p2p_media_list`(
  IN _peer_id VARCHAR(16) CHARACTER SET ascii,
  IN _kind VARCHAR(8),
  IN _page INT
)
BEGIN
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _peer_db VARCHAR(255);
  DECLARE _hub VARCHAR(16) CHARACTER SET ascii;
  DECLARE _hub_db VARCHAR(255);
  DECLARE _size INT DEFAULT 60;
  DECLARE _offset INT DEFAULT 0;
  DECLARE _done INT DEFAULT 0;
  DECLARE _hubs CURSOR FOR SELECT DISTINCT hub_id FROM _p2p_att;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _done = 1;

  IF _kind = 'link' THEN
    SET _size = 30;
  END IF;
  SET _offset = (GREATEST(IFNULL(_page, 1), 1) - 1) * _size;

  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;
  SELECT db_name FROM yp.entity WHERE id = _peer_id INTO _peer_db;
  SET _done = 0;

  DROP TEMPORARY TABLE IF EXISTS _p2p_msg;
  CREATE TEMPORARY TABLE _p2p_msg (
    message_id VARCHAR(16) CHARACTER SET ascii,
    message MEDIUMTEXT,
    attachment LONGTEXT,
    ctime INT(11) NOT NULL
  );
  INSERT INTO _p2p_msg SELECT message_id, message, attachment, ctime FROM p2p_channel
    WHERE peer_id = _peer_id AND status = 'active';
  IF _peer_db IS NOT NULL AND EXISTS (SELECT 1 FROM information_schema.tables
      WHERE table_schema = _peer_db AND table_name = 'p2p_channel') THEN
    SET @_s = CONCAT("INSERT INTO _p2p_msg SELECT message_id, message, attachment, ctime FROM `",
      _peer_db, "`.p2p_channel WHERE peer_id = ? AND status = 'active'");
    PREPARE _st FROM @_s; EXECUTE _st USING _uid; DEALLOCATE PREPARE _st;
  END IF;

  IF _kind = 'link' THEN
    SELECT
      m.message_id,
      m.ctime,
      SUBSTRING(REGEXP_REPLACE(m.message, '<[^>]*>', ''), 1, 300) AS preview,
      REGEXP_SUBSTR(m.message, 'https?://[^[:space:]<>"'']+') AS url
    FROM _p2p_msg m
    WHERE m.message REGEXP 'https?://'
    ORDER BY m.ctime DESC, m.message_id DESC
    LIMIT _offset, _size;
  ELSE
    DROP TEMPORARY TABLE IF EXISTS _p2p_att;
    CREATE TEMPORARY TABLE _p2p_att (
      nid VARCHAR(16) CHARACTER SET ascii,
      hub_id VARCHAR(16) CHARACTER SET ascii,
      idx INT,
      message_id VARCHAR(16) CHARACTER SET ascii,
      ctime INT(11),
      category VARCHAR(16) DEFAULT NULL,
      filename VARCHAR(512) DEFAULT NULL,
      extension VARCHAR(100) DEFAULT NULL,
      filesize BIGINT UNSIGNED DEFAULT NULL,
      duration VARCHAR(32) DEFAULT NULL
    );
    INSERT INTO _p2p_att (nid, hub_id, idx, message_id, ctime)
      SELECT j.nid, j.hub_id, j.idx, m.message_id, m.ctime FROM _p2p_msg m
      JOIN JSON_TABLE(IF(JSON_VALID(m.attachment), m.attachment, '[]'), '$[*]'
        COLUMNS (idx FOR ORDINALITY, nid VARCHAR(16) PATH '$.nid', hub_id VARCHAR(16) PATH '$.hub_id')) j;

    OPEN _hubs;
    hubs: LOOP
      FETCH _hubs INTO _hub;
      IF _done THEN LEAVE hubs; END IF;
      SET _hub_db = NULL;
      SELECT db_name FROM yp.entity WHERE id = _hub INTO _hub_db;
      SET _done = 0; -- the SELECT … INTO above may have tripped the handler
      IF _hub_db IS NOT NULL AND EXISTS (SELECT 1 FROM information_schema.tables
          WHERE table_schema = _hub_db AND table_name = 'media') THEN
        SET @_s = CONCAT("UPDATE _p2p_att a JOIN `", _hub_db,
          "`.media m ON m.id = a.nid AND m.status = 'active' ",
          "SET a.category = m.category, a.filename = m.user_filename, a.extension = m.extension, ",
          "a.filesize = m.filesize, a.duration = JSON_VALUE(m.metadata, '$.duration') WHERE a.hub_id = ?");
        PREPARE _st FROM @_s; EXECUTE _st USING _hub; DEALLOCATE PREPARE _st;
      END IF;
    END LOOP;
    CLOSE _hubs;

    SELECT nid, hub_id, category, filename, extension, filesize, duration, ctime, message_id
    FROM _p2p_att
    WHERE category IS NOT NULL
      AND CASE _kind
        WHEN 'photo' THEN category IN ('image','vector')
        WHEN 'video' THEN category = 'video'
        WHEN 'file'  THEN category NOT IN ('image','vector','video','folder','hub','root')
        ELSE 0
      END
    ORDER BY ctime DESC, message_id DESC, idx DESC
    LIMIT _offset, _size;
  END IF;
END $

DELIMITER ;
