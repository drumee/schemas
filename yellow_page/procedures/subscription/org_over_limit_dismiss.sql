DELIMITER $

-- =========================================================
-- org_over_limit_dismiss
-- "Remind me later" on the over-limit popup: snooze the popup
-- for ONE admin (keyed by uid inside $.over_limit.snooze) until
-- _until (unix seconds). Server-authoritative on purpose — the
-- design forbids localStorage so a dismissal can never outlive
-- its intent; the whole $.over_limit block (snoozes included)
-- is dropped by org_over_limit_set the moment the org is back
-- within limits. Guarded on an existing over_limit block so a
-- stale client can't graffiti metadata after resolution.
-- _uid is an internal 16-hex ascii id — safe to inline in the
-- JSON path.
-- =========================================================
DROP PROCEDURE IF EXISTS `org_over_limit_dismiss`$
CREATE PROCEDURE `org_over_limit_dismiss`(
  IN _org_id VARCHAR(16) CHARACTER SET ascii,
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _until INT(11) UNSIGNED
)
BEGIN
  -- Inner JSON_SET first guarantees $.over_limit.snooze exists as an object:
  -- JSON_SET only auto-creates the LAST path leg, so writing the per-uid key
  -- straight onto a block with no snooze map would be a silent no-op.
  UPDATE organisation
  SET metadata = JSON_SET(
    JSON_SET(
      metadata,
      '$.over_limit.snooze',
      IFNULL(JSON_QUERY(metadata, '$.over_limit.snooze'), JSON_OBJECT())
    ),
    CONCAT('$.over_limit.snooze."', _uid, '"'), IFNULL(_until, 0)
  )
  WHERE id = _org_id
    AND JSON_VALUE(metadata, '$.over_limit.state') IS NOT NULL;

  SELECT ROW_COUNT() AS snoozed;
END $

DELIMITER ;
