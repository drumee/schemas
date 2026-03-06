DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_add_autorized_node`$
CREATE PROCEDURE `mfs_add_autorized_node`(
  IN _args JSON
)
BEGIN
  DECLARE _sessionKey VARCHAR(264) CHARACTER SET ascii;
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _nid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _expiry INT UNSIGNED;

  SELECT JSON_VALUE(_args, "$.sessionKey") INTO _sessionKey;
  SELECT JSON_VALUE(_args, "$.hub_id") INTO _hub_id;
  SELECT JSON_VALUE(_args, "$.nid") INTO _nid;
  SELECT JSON_VALUE(_args, "$.uid") INTO _uid;
  SELECT JSON_VALUE(_args, "$.expiry") INTO _expiry;

  IF _expiry IS NULL THEN 
    SELECT 0 INTO _expiry;
  END IF;

  IF _expiry > 0 THEN 
    SELECT UNIX_TIMESTAMP() + _expiry INTO _expiry;
  END IF;

  IF _sessionKey IS NOT NULL THEN
    INSERT INTO mfs_authorized_node (
      sessionKey,
      hub_id,
      nid,
      uid,
      expiry,
      ctime
    ) VALUES (
      _sessionKey,
      _hub_id,
      _nid,
      _uid,
      _expiry,
      UNIX_TIMESTAMP()
    )
    ON DUPLICATE KEY UPDATE expiry = _expiry;
  END IF;

END$

DELIMITER ;