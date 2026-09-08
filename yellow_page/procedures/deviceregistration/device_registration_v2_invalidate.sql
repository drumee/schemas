DELIMITER $

DROP PROCEDURE IF EXISTS `device_registration_v2_invalidate`$
CREATE PROCEDURE `device_registration_v2_invalidate`(
  IN _registration_id BIGINT UNSIGNED,
  IN _binding_version BIGINT UNSIGNED,
  IN _state_version BIGINT UNSIGNED
)
main: BEGIN
  DECLARE _now DATETIME(6) DEFAULT UTC_TIMESTAMP(6);
  DECLARE _uid VARCHAR(16) DEFAULT NULL;
  DECLARE _current_state VARCHAR(16) DEFAULT NULL;
  DECLARE _current_binding BIGINT UNSIGNED DEFAULT NULL;
  DECLARE _current_state_version BIGINT UNSIGNED DEFAULT NULL;
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
  INTO _uid, _current_state, _current_binding, _current_state_version
  FROM device_registration_v2
  WHERE registration_id = _registration_id
  LIMIT 1 FOR UPDATE;

  IF _found = 0 OR _current_binding <> _binding_version
    OR _current_state_version <> _state_version
    OR _current_state <> 'active'
  THEN
    COMMIT;
    SELECT 0 AS changed;
    LEAVE main;
  END IF;

  INSERT IGNORE INTO device_registration_v2_tombstone (
    registration_id, uid, binding_version, state_version,
    result_binding_version, result_state_version, reason, ctime
  ) VALUES (
    _registration_id, _uid, _binding_version, _state_version,
    _binding_version, _state_version + 1, 'invalidated', _now
  );
  UPDATE device_registration_v2
  SET state = 'inactive', state_version = state_version + 1,
      expires_at = _now, mtime = _now
  WHERE registration_id = _registration_id
    AND binding_version = _binding_version
    AND state_version = _state_version
    AND state = 'active';
  COMMIT;
  SELECT 1 AS changed;
END$

DELIMITER ;
