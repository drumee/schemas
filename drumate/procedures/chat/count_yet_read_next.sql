DELIMITER $

DROP PROCEDURE IF EXISTS `count_yet_read_next`$
CREATE PROCEDURE `count_yet_read_next`(
  IN _uid     VARCHAR(16),
  IN _peer_id VARCHAR(16)
)
BEGIN
  DECLARE _total_cnt INT(11) UNSIGNED DEFAULT 0;
  DECLARE _room_cnt  INT(11) UNSIGNED DEFAULT 0;

  -- Total: number of P2P conversations with unread messages
  SELECT COUNT(*)
  FROM p2p_time pt
  LEFT JOIN p2p_read pr ON pr.peer_id = pt.peer_id AND pr.uid = _uid
  WHERE pt.ref_ctime > IFNULL(pr.ref_ctime, 0)
  INTO _total_cnt;

  -- Room: whether the specific conversation with _peer_id has unread (1 or 0)
  SELECT CASE WHEN pt.ref_ctime > IFNULL(pr.ref_ctime, 0) THEN 1 ELSE 0 END
  FROM p2p_time pt
  LEFT JOIN p2p_read pr ON pr.peer_id = pt.peer_id AND pr.uid = _uid
  WHERE pt.peer_id = _peer_id
  INTO _room_cnt;

  SELECT _total_cnt AS total, _room_cnt AS room;

END $

DELIMITER ;