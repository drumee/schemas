DELIMITER $
/*

  Status : active 

*/

DROP PROCEDURE IF EXISTS `count_yet_read`$
CREATE PROCEDURE `count_yet_read`(
IN _in JSON,
OUT _out JSON
)
BEGIN
   
DECLARE _peer_id VARCHAR(16);
DECLARE _uid VARCHAR(16);
DECLARE _total_cnt int(11) unsigned DEFAULT 0;
DECLARE _room_cnt int(11) unsigned DEFAULT 0;

  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;
  SELECT JSON_UNQUOTE(JSON_EXTRACT(_in, "$.entity_id")) INTO _peer_id;

  -- Total: count of P2P conversations with unread messages
  SELECT COUNT(*)
  FROM p2p_time pt
  LEFT JOIN p2p_read pr ON pr.peer_id = pt.peer_id AND pr.uid = _uid
  WHERE pt.ref_ctime > IFNULL(pr.ref_ctime, 0)
  INTO _total_cnt;

  -- Room: whether the specific conversation with _peer_id has unread messages
  SELECT CASE WHEN pt.ref_ctime > IFNULL(pr.ref_ctime, 0) THEN 1 ELSE 0 END
  FROM p2p_time pt
  LEFT JOIN p2p_read pr ON pr.peer_id = pt.peer_id AND pr.uid = _uid
  WHERE pt.peer_id = _peer_id
  INTO _room_cnt;

  SELECT JSON_MERGE(IFNULL(_out,'{}'), JSON_OBJECT('total', _total_cnt), JSON_OBJECT('room', _room_cnt)) INTO _out;

END$  

DELIMITER ;