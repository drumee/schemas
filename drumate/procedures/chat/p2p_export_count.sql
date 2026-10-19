DELIMITER $

-- =========================================================
-- p2p_export_count
-- Messages of ONE direct conversation within [_start, _end] (NULL = open):
-- the viewer's p2p_channel plus the peer's (a DM message lives only in its
-- sender's DB). Active only. Feeds the export's 10k guard and its card.
-- =========================================================
DROP PROCEDURE IF EXISTS `p2p_export_count`$
CREATE PROCEDURE `p2p_export_count`(
  IN _peer_id VARCHAR(16) CHARACTER SET ascii,
  IN _start INT(11),
  IN _end INT(11)
)
BEGIN
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _peer_db VARCHAR(255);
  DECLARE CONTINUE HANDLER FOR NOT FOUND BEGIN END;

  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;
  SELECT db_name FROM yp.entity WHERE id = _peer_id INTO _peer_db;

  DROP TEMPORARY TABLE IF EXISTS _p2p_x;
  CREATE TEMPORARY TABLE _p2p_x (ctime INT(11));
  INSERT INTO _p2p_x SELECT ctime FROM p2p_channel WHERE peer_id = _peer_id AND status = 'active';
  IF _peer_db IS NOT NULL AND EXISTS (SELECT 1 FROM information_schema.tables
      WHERE table_schema = _peer_db AND table_name = 'p2p_channel') THEN
    SET @_s = CONCAT("INSERT INTO _p2p_x SELECT ctime FROM `", _peer_db,
      "`.p2p_channel WHERE peer_id = ? AND status = 'active'");
    PREPARE _st FROM @_s; EXECUTE _st USING _uid; DEALLOCATE PREPARE _st;
  END IF;

  SELECT COUNT(*) AS message_count FROM _p2p_x
    WHERE (_start IS NULL OR ctime >= _start) AND (_end IS NULL OR ctime <= _end);
  DROP TEMPORARY TABLE IF EXISTS _p2p_x;
END$

DELIMITER ;
