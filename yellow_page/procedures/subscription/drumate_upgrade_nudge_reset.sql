DELIMITER $

-- =========================================================
-- drumate_upgrade_nudge_reset
-- Personal-account twin of org_upgrade_nudge_reset: drops
-- $.upgrade_nudge from drumate.profile so every threshold
-- re-arms against the account's NEW plan ("until upgraded").
-- =========================================================
DROP PROCEDURE IF EXISTS `drumate_upgrade_nudge_reset`$
CREATE PROCEDURE `drumate_upgrade_nudge_reset`(
  IN _uid VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  UPDATE drumate
  SET profile = JSON_REMOVE(
    IF(profile IS NULL OR profile = '' OR NOT JSON_VALID(profile), '{}', profile),
    '$.upgrade_nudge'
  )
  WHERE id = _uid;

  SELECT ROW_COUNT() AS affected;
END$

DELIMITER ;
