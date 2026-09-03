DELIMITER $

DROP PROCEDURE IF EXISTS `push_registration_list`$
CREATE PROCEDURE `push_registration_list`(
  IN _uids LONGTEXT,
  IN _after_registration_id BIGINT UNSIGNED,
  IN _limit INT UNSIGNED
)
main: BEGIN
  DECLARE _cursor BIGINT UNSIGNED DEFAULT IFNULL(_after_registration_id, 0);
  DECLARE _safe_limit INT UNSIGNED DEFAULT LEAST(GREATEST(IFNULL(_limit, 100), 1), 500);

  IF _uids IS NULL OR JSON_VALID(_uids) = 0 OR JSON_TYPE(_uids) <> 'ARRAY' THEN
    SELECT NULL AS registration_id, NULL AS uid,
      NULL AS registration_kind, NULL AS binding_version,
      NULL AS state_version
    WHERE 1 = 0;
    LEAVE main;
  END IF;

  SELECT r.registration_id, r.uid, r.registration_kind,
    r.binding_version, r.state_version
  FROM device_registration_v2 r
  WHERE r.state = 'active'
    AND r.expires_at > UTC_TIMESTAMP(6)
    AND r.registration_id > _cursor
    AND r.uid IN (
      SELECT j.uid
      FROM JSON_TABLE(
        _uids,
        '$[*]' COLUMNS(uid VARCHAR(16) PATH '$')
      ) AS j
      WHERE j.uid IS NOT NULL AND j.uid <> ''
    )
  ORDER BY r.registration_id
  LIMIT _safe_limit;
END$

DELIMITER ;
