DELIMITER $

-- Authenticated mobile push registration. Existing-row ownership, state
-- recovery, and token rotation require the exact server-issued CAS tuple.
DROP PROCEDURE IF EXISTS `device_registration_v2`$
CREATE PROCEDURE `device_registration_v2`(
  IN _uid VARCHAR(16),
  IN _registration_kind VARCHAR(16),
  IN _registration_digest CHAR(64),
  IN _push_token TEXT,
  IN _device_id VARCHAR(255),
  IN _device_type VARCHAR(32),
  IN _registration_id BIGINT UNSIGNED,
  IN _binding_version BIGINT UNSIGNED,
  IN _state_version BIGINT UNSIGNED
)
main: BEGIN
  DECLARE _now DATETIME(6) DEFAULT UTC_TIMESTAMP(6);
  DECLARE _new_expiry DATETIME(6);
  DECLARE _has_cas TINYINT UNSIGNED DEFAULT 0;
  DECLARE _found TINYINT UNSIGNED DEFAULT 0;
  DECLARE _current_id BIGINT UNSIGNED DEFAULT NULL;
  DECLARE _current_uid VARCHAR(16) DEFAULT NULL;
  DECLARE _current_kind VARCHAR(16) DEFAULT NULL;
  DECLARE _current_digest CHAR(64) DEFAULT NULL;
  DECLARE _current_state VARCHAR(16) DEFAULT NULL;
  DECLARE _current_binding BIGINT UNSIGNED DEFAULT NULL;
  DECLARE _current_state_version BIGINT UNSIGNED DEFAULT NULL;
  DECLARE _current_expiry DATETIME(6) DEFAULT NULL;
  DECLARE _next_binding BIGINT UNSIGNED DEFAULT NULL;
  DECLARE _next_state BIGINT UNSIGNED DEFAULT NULL;
  DECLARE _reason VARCHAR(16) DEFAULT NULL;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _found = 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET _new_expiry = TIMESTAMPADD(DAY, 30, _now);
  SET _has_cas = IF(
    _registration_id IS NOT NULL
    AND _binding_version IS NOT NULL
    AND _state_version IS NOT NULL,
    1,
    0
  );

  IF _uid IS NULL OR _uid = ''
    OR _registration_kind <> 'token'
    OR _registration_digest IS NULL
    OR _registration_digest NOT REGEXP BINARY '^[0-9a-f]{64}$'
    OR _push_token IS NULL OR _push_token = ''
    OR _registration_digest <> SHA2(_push_token, 256)
    OR _device_id IS NULL OR _device_id = ''
    OR _device_type IS NULL OR _device_type = ''
    OR ((_registration_id IS NULL) + (_binding_version IS NULL) + (_state_version IS NULL)) NOT IN (0, 3)
  THEN
    SELECT 0 AS applied, NULL AS registration_id, NULL AS uid,
      NULL AS registration_kind, NULL AS state, NULL AS binding_version,
      NULL AS state_version, NULL AS expires_at;
    LEAVE main;
  END IF;

  START TRANSACTION;

  IF _has_cas = 1 THEN
    SET _found = 1;
    SELECT registration_id, uid, registration_kind, registration_digest,
      state, binding_version, state_version, expires_at
    INTO _current_id, _current_uid, _current_kind, _current_digest,
      _current_state, _current_binding, _current_state_version, _current_expiry
    FROM device_registration_v2
    WHERE registration_id = _registration_id
    LIMIT 1 FOR UPDATE;

    IF _found = 0
      OR _current_kind <> _registration_kind
      OR _current_binding <> _binding_version
      OR _current_state_version <> _state_version
    THEN
      COMMIT;
      SELECT 0 AS applied, NULL AS registration_id, NULL AS uid,
        NULL AS registration_kind, NULL AS state, NULL AS binding_version,
        NULL AS state_version, NULL AS expires_at;
      LEAVE main;
    END IF;

    IF _current_digest <> _registration_digest
      AND EXISTS(
        SELECT 1 FROM device_registration_v2
        WHERE registration_kind = _registration_kind
          AND registration_digest = _registration_digest
          AND registration_id <> _current_id
      )
    THEN
      COMMIT;
      SELECT 0 AS applied, NULL AS registration_id, NULL AS uid,
        NULL AS registration_kind, NULL AS state, NULL AS binding_version,
        NULL AS state_version, NULL AS expires_at;
      LEAVE main;
    END IF;

    SET _next_binding = _current_binding + IF(_current_uid <> _uid, 1, 0);
    SET _reason = CASE
      WHEN _current_uid <> _uid THEN 'rebound'
      WHEN _current_digest <> _registration_digest THEN 'token_rotated'
      WHEN _current_state <> 'active' OR _current_expiry <= _now THEN 'reactivated'
      ELSE NULL
    END;
    SET _next_state = _current_state_version + IF(_reason IS NULL, 0, 1);

    IF _reason IS NOT NULL THEN
      INSERT IGNORE INTO device_registration_v2_tombstone (
        registration_id, uid, binding_version, state_version,
        result_binding_version, result_state_version, reason, ctime
      ) VALUES (
        _current_id, _current_uid, _current_binding, _current_state_version,
        _next_binding, _next_state, _reason, _now
      );
    END IF;

    UPDATE device_registration_v2
    SET registration_kind = _registration_kind,
        registration_digest = _registration_digest,
        push_token = _push_token,
        uid = _uid,
        device_id = _device_id,
        device_type = _device_type,
        state = 'active',
        binding_version = _next_binding,
        state_version = _next_state,
        expires_at = _new_expiry,
        mtime = _now
    WHERE registration_id = _current_id;
  ELSE
    INSERT INTO device_registration_v2 (
      registration_kind, registration_digest, push_token, uid,
      device_id, device_type, state, binding_version, state_version,
      expires_at, ctime, mtime
    ) VALUES (
      _registration_kind, _registration_digest, _push_token, _uid,
      _device_id, _device_type, 'active', 1, 1,
      _new_expiry, _now, _now
    ) ON DUPLICATE KEY UPDATE registration_id = LAST_INSERT_ID(registration_id);

    SET _found = 1;
    SELECT registration_id, uid, registration_kind, registration_digest,
      state, binding_version, state_version, expires_at
    INTO _current_id, _current_uid, _current_kind, _current_digest,
      _current_state, _current_binding, _current_state_version, _current_expiry
    FROM device_registration_v2
    WHERE registration_kind = _registration_kind
      AND registration_digest = _registration_digest
    LIMIT 1 FOR UPDATE;

    IF _found = 0 OR _current_uid <> _uid
      OR _current_state <> 'active' OR _current_expiry <= _now
    THEN
      COMMIT;
      SELECT 0 AS applied, NULL AS registration_id, NULL AS uid,
        NULL AS registration_kind, NULL AS state, NULL AS binding_version,
        NULL AS state_version, NULL AS expires_at;
      LEAVE main;
    END IF;

    UPDATE device_registration_v2
    SET push_token = _push_token,
        device_id = _device_id,
        device_type = _device_type,
        expires_at = _new_expiry,
        mtime = _now
    WHERE registration_id = _current_id;
  END IF;

  COMMIT;

  SELECT 1 AS applied, registration_id, uid, registration_kind, state,
    binding_version, state_version, UNIX_TIMESTAMP(expires_at) AS expires_at
  FROM device_registration_v2
  WHERE registration_id = _current_id AND uid = _uid;
END$

DELIMITER ;
