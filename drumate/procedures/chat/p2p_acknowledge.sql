DELIMITER $

DROP PROCEDURE IF EXISTS `p2p_acknowledge`$
CREATE PROCEDURE `p2p_acknowledge`(
  IN _in JSON
)
BEGIN
  DECLARE _uid       VARCHAR(16) CHARACTER SET ascii;
  DECLARE _peer_id   VARCHAR(16) CHARACTER SET ascii;
  DECLARE _ref_ctime INT(11) UNSIGNED;

  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;
  SELECT JSON_VALUE(_in, "$.peer_id")   INTO _peer_id;
  SELECT JSON_VALUE(_in, "$.ref_ctime") INTO _ref_ctime;

  IF _ref_ctime IS NULL THEN
    SELECT UNIX_TIMESTAMP() INTO _ref_ctime;
  END IF;

  INSERT INTO p2p_read (peer_id, uid, ref_ctime, ctime)
  SELECT _peer_id, _uid, _ref_ctime, UNIX_TIMESTAMP()
  ON DUPLICATE KEY UPDATE
    ref_ctime = GREATEST(ref_ctime, VALUES(ref_ctime)),
    ctime = VALUES(ctime);

END $

DELIMITER ;