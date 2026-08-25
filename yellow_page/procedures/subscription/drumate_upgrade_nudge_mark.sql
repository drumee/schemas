DELIMITER $

-- =========================================================
-- drumate_upgrade_nudge_mark
-- Personal-account twin of org_upgrade_nudge_mark (Free -> Pro,
-- Pro -> Team routes of the upgrade-nudge popups). Same gate,
-- same JSON block shape, but the home is drumate.profile
-- ($.upgrade_nudge) because a personal account has no
-- organisation row. The member map still keys on the uid so the
-- JS lib reads both scopes with one code path.
--
--   granted       1 = show the popup, 0 = suppressed
--   seen_already  this threshold was already shown
--   capped_today  daily cap hit
-- =========================================================
DROP PROCEDURE IF EXISTS `drumate_upgrade_nudge_mark`$
CREATE PROCEDURE `drumate_upgrade_nudge_mark`(
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _trigger VARCHAR(32) CHARACTER SET ascii,
  IN _day VARCHAR(10) CHARACTER SET ascii,
  IN _plan VARCHAR(80) CHARACTER SET ascii
)
BEGIN
  DECLARE _seen_path VARCHAR(96);
  DECLARE _cap_path VARCHAR(64);
  DECLARE _fired_path VARCHAR(64);
  DECLARE _granted TINYINT DEFAULT 0;

  SET _seen_path = CONCAT('$.upgrade_nudge.seen.', _trigger, '.', _uid);
  SET _cap_path = CONCAT('$.upgrade_nudge.last_shown.', _uid);
  SET _fired_path = CONCAT('$.upgrade_nudge.fired.', _trigger);

  UPDATE drumate
  SET profile = JSON_MERGE_PATCH(
    IF(profile IS NULL OR profile = '' OR NOT JSON_VALID(profile), '{}', profile),
    JSON_OBJECT('upgrade_nudge', JSON_OBJECT(
      'plan', _plan,
      'fired', JSON_OBJECT(
        _trigger,
        CAST(COALESCE(JSON_VALUE(profile, _fired_path), UNIX_TIMESTAMP()) AS INTEGER)
      ),
      'seen', JSON_OBJECT(_trigger, JSON_OBJECT(_uid, UNIX_TIMESTAMP())),
      'last_shown', JSON_OBJECT(_uid, _day)
    ))
  )
  WHERE id = _uid
    AND JSON_VALUE(profile, _seen_path) IS NULL
    AND (JSON_VALUE(profile, _cap_path) IS NULL
         OR JSON_VALUE(profile, _cap_path) <> _day);

  SET _granted = IF(ROW_COUNT() > 0, 1, 0);

  SELECT
    _granted AS granted,
    IF(_granted = 1, 0,
       IF(JSON_VALUE(profile, _seen_path) IS NOT NULL, 1, 0)) AS seen_already,
    IF(_granted = 1, 0,
       IF(JSON_VALUE(profile, _cap_path) = _day, 1, 0)) AS capped_today
  FROM drumate WHERE id = _uid;
END$

DELIMITER ;
