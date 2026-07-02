DELIMITER $

DROP PROCEDURE IF EXISTS `organisation_set_retention`$
CREATE PROCEDURE `organisation_set_retention`(
  IN _id VARCHAR(16),
  IN _retention_days INT,
  IN _apply_immediately TINYINT,
  IN _allow_members_view TINYINT,
  IN _allow_editors_restore TINYINT
)
BEGIN
  -- Versioning retention policy is org-wide; store it in organisation.metadata
  -- (longtext JSON, already holds ident/name/owner_id). JSON_SET preserves the
  -- existing keys. Guard against a NULL / non-JSON legacy metadata value.
  UPDATE organisation
  SET metadata = JSON_SET(
    IF(metadata IS NULL OR metadata = '' OR NOT JSON_VALID(metadata), '{}', metadata),
    '$.version_retention_days',        _retention_days,
    '$.version_apply_immediately',     _apply_immediately,
    '$.version_allow_members_view',    _allow_members_view,
    '$.version_allow_editors_restore', _allow_editors_restore
  )
  WHERE id = _id;

  SELECT ROW_COUNT() AS updated;
END$

DELIMITER ;
