DELIMITER $
DROP PROCEDURE IF EXISTS `pages_to_read`$
CREATE PROCEDURE `pages_to_read`(
  _peer_id  VARCHAR(16),
  _uid      VARCHAR(16)
)
BEGIN
  DECLARE _page     int(11);
  DECLARE _ref_ctime int(11) unsigned DEFAULT 0;
  DECLARE _pos_cnt  int(11) unsigned DEFAULT 0;
  DECLARE _all_cnt  int(11) unsigned DEFAULT 0;

  DECLARE _range bigint;
  DECLARE _offset bigint;

  CALL pageToLimits(_page, _offset, _range);

  -- My read position (ctime-based cursor)
  SELECT ref_ctime FROM p2p_read WHERE peer_id = _peer_id AND uid = _uid INTO _ref_ctime;

  -- Count my sent messages to peer (conservative: does not include cross-DB messages from peer)
  SELECT COUNT(*) FROM p2p_channel WHERE peer_id = _peer_id INTO _all_cnt;

  -- Count my sent messages that were already read (before read cursor)
  SELECT COUNT(*) FROM p2p_channel
  WHERE peer_id = _peer_id AND ctime <= _ref_ctime
  INTO _pos_cnt;

  SELECT FLOOR((IFNULL(_all_cnt, 0) - IFNULL(_pos_cnt, 0)) / _range) + 1 page;

END$  

DELIMITER ;