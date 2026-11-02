DELIMITER $

-- =========================================================
-- p2p_media_stats
-- Photo / video / file / link counts of ONE direct conversation: the
-- viewer's p2p_channel (peer_id = _peer_id) plus the peer's (peer_id =
-- viewer) — a DM message is stored only in its sender's DB. Attachments
-- are resolved in their own hub (the sender's wicket), active nodes only.
-- =========================================================
DROP PROCEDURE IF EXISTS `p2p_media_stats`$
CREATE PROCEDURE `p2p_media_stats`(
  IN _peer_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _peer_db VARCHAR(255);
  DECLARE _hub VARCHAR(16) CHARACTER SET ascii;
  DECLARE _hub_db VARCHAR(255);
  DECLARE _done INT DEFAULT 0;
  DECLARE _hubs CURSOR FOR SELECT DISTINCT hub_id FROM _p2p_att;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _done = 1;

  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;
  SELECT db_name FROM yp.entity WHERE id = _peer_id INTO _peer_db;
  -- A missing peer (deleted account) trips the NOT FOUND handler here; reset
  -- it or the hub loop below would exit before its first fetch.
  SET _done = 0;

  DROP TEMPORARY TABLE IF EXISTS _p2p_msg;
  CREATE TEMPORARY TABLE _p2p_msg (message MEDIUMTEXT, attachment LONGTEXT);
  INSERT INTO _p2p_msg SELECT message, attachment FROM p2p_channel
    WHERE peer_id = _peer_id AND status = 'active';
  IF _peer_db IS NOT NULL AND EXISTS (SELECT 1 FROM information_schema.tables
      WHERE table_schema = _peer_db AND table_name = 'p2p_channel') THEN
    SET @_s = CONCAT("INSERT INTO _p2p_msg SELECT message, attachment FROM `", _peer_db,
      "`.p2p_channel WHERE peer_id = ? AND status = 'active'");
    PREPARE _st FROM @_s; EXECUTE _st USING _uid; DEALLOCATE PREPARE _st;
  END IF;

  DROP TEMPORARY TABLE IF EXISTS _p2p_att;
  CREATE TEMPORARY TABLE _p2p_att (
    nid VARCHAR(16) CHARACTER SET ascii, hub_id VARCHAR(16) CHARACTER SET ascii,
    category VARCHAR(16) DEFAULT NULL
  );
  INSERT INTO _p2p_att (nid, hub_id)
    SELECT j.nid, j.hub_id FROM _p2p_msg m
    JOIN JSON_TABLE(IF(JSON_VALID(m.attachment), m.attachment, '[]'), '$[*]'
      COLUMNS (nid VARCHAR(16) PATH '$.nid', hub_id VARCHAR(16) PATH '$.hub_id')) j;

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
        "`.media m ON m.id = a.nid AND m.status = 'active' SET a.category = m.category WHERE a.hub_id = ?");
      PREPARE _st FROM @_s; EXECUTE _st USING _hub; DEALLOCATE PREPARE _st;
    END IF;
  END LOOP;
  CLOSE _hubs;

  SELECT
    IFNULL(SUM(category IN ('image','vector')), 0) AS photos,
    IFNULL(SUM(category = 'video'), 0) AS videos,
    IFNULL(SUM(category NOT IN ('image','vector','video','folder','hub','root')), 0) AS files,
    (SELECT COUNT(*) FROM _p2p_msg WHERE message REGEXP 'https?://') AS links
  FROM _p2p_att WHERE category IS NOT NULL;
END $

DELIMITER ;
