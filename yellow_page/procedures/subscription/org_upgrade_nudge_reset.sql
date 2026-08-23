DELIMITER $

-- =========================================================
-- org_upgrade_nudge_reset
-- "Once per threshold ... UNTIL UPGRADED": a committed plan
-- upgrade wipes the whole $.upgrade_nudge block (fired, seen
-- and the daily-cap map), so the thresholds re-arm against the
-- NEW plan's limits. Called from the entitlement-raising
-- commits (stripe webhook, promo claim) — never from
-- resolution/cleanup paths, which must not re-arm anything.
--
-- Same JSON hygiene as org_over_limit_set: invalid/empty
-- metadata is treated as {} so the remove can never throw.
-- =========================================================
DROP PROCEDURE IF EXISTS `org_upgrade_nudge_reset`$
CREATE PROCEDURE `org_upgrade_nudge_reset`(
  IN _org_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  UPDATE organisation
  SET metadata = JSON_REMOVE(
    IF(metadata IS NULL OR metadata = '' OR NOT JSON_VALID(metadata), '{}', metadata),
    '$.upgrade_nudge'
  )
  WHERE id = _org_id;

  SELECT ROW_COUNT() AS affected;
END$

DELIMITER ;
