DELIMITER $

DROP PROCEDURE IF EXISTS `device_registration_v2_unregister`$
CREATE PROCEDURE `device_registration_v2_unregister`(
  IN _uid VARCHAR(16),
  IN _registration_id BIGINT UNSIGNED,
  IN _binding_version BIGINT UNSIGNED,
  IN _state_version BIGINT UNSIGNED
)
main: BEGIN
  DECLARE _now DATETIME(6) DEFAULT UTC_TIMESTAMP(6);
  DECLARE _current_uid VARCHAR(16) DEFAULT NULL;
  DECLARE _current_state VARCHAR(16) DEFAULT NULL;
  DECLARE _current_binding BIGINT UNSIGNED DEFAULT NULL;
  DECLARE _current_state_version BIGINT UNSIGNED DEFAULT NULL;
  DECLARE _result_state_version BIGINT UNSIGNED DEFAULT NULL;
  DECLARE _found TINYINT UNSIGNED DEFAULT 0;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _found = 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  SET _found = 1;
  SELECT uid, state, binding_version, state_version
  INTO _current_uid, _current_state, _current_binding, _current_state_version
  FROM device_registration_v2
  WHERE registration_id = _registration_id
  LIMIT 1 FOR UPDATE;

  IF _found = 1 AND _current_uid = _uid
    AND _current_binding = _binding_version
    AND _current_state_version = _state_version
    AND _current_state = 'active'
  THEN
    SET _result_state_version = _current_state_version + 1;
    INSERT IGNORE INTO device_registration_v2_tombstone (
      registration_id, uid, binding_version, state_version,
      result_binding_version, result_state_version, reason, ctime
    ) VALUES (
      _registration_id, _uid, _current_binding, _current_state_version,
      _current_binding, _result_state_version, 'unregistered', _now
    );
    UPDATE device_registration_v2
    SET state = 'tombstoned', state_version = _result_state_version,
        expires_at = _now, mtime = _now
    WHERE registration_id = _registration_id;
    COMMIT;
    SELECT _registration_id AS registration_id, 'tombstoned' AS state,
      _current_binding AS binding_version,
      _result_state_version AS state_version, 1 AS changed;
    LEAVE main;
  END IF;

  COMMIT;
  SELECT registration_id, 'tombstoned' AS state,
    result_binding_version AS binding_version,
    result_state_version AS state_version, 0 AS changed
  FROM device_registration_v2_tombstone
  WHERE registration_id = _registration_id
    AND uid = _uid
    AND binding_version = _binding_version
    AND state_version = _state_version
    AND reason = 'unregistered'
  LIMIT 1;
END$

DELIMITER ;
