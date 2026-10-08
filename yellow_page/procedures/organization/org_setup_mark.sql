DELIMITER $

-- =========================================================
-- org_setup_mark
-- =========================================================
-- Record that the organisation's setup wizard was finished or skipped, so the
-- desk stops offering it. Stamped with the time in organisation.metadata
-- ($.org_setup_done); every other metadata key is kept.
DROP PROCEDURE IF EXISTS `org_setup_mark`$
CREATE PROCEDURE `org_setup_mark`(
  IN _domain_id INT UNSIGNED
)
BEGIN
  UPDATE organisation
     SET metadata = JSON_SET(
       IF(metadata IS NULL OR metadata = '' OR NOT JSON_VALID(metadata), '{}', metadata),
       '$.org_setup_done', UNIX_TIMESTAMP()
     )
   WHERE domain_id = _domain_id;

  SELECT ROW_COUNT() AS updated;
END$

DELIMITER ;
