DELIMITER $

DROP PROCEDURE IF EXISTS `push_registration_get`$
CREATE PROCEDURE `push_registration_get`(
  IN _registration_id BIGINT UNSIGNED,
  IN _uid VARCHAR(16),
  IN _binding_version BIGINT UNSIGNED,
  IN _state_version BIGINT UNSIGNED
)
BEGIN
  SELECT registration_id, uid, registration_kind, push_token,
    binding_version, state_version
  FROM device_registration_v2
  WHERE registration_id = _registration_id
    AND uid = _uid
    AND binding_version = _binding_version
    AND state_version = _state_version
    AND state = 'active'
    AND expires_at > UTC_TIMESTAMP(6)
  LIMIT 1;
END$

DELIMITER ;
