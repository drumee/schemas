DELIMITER $

-- =========================================================
-- org_upgrade_nudge_mark
-- The shared cross-trigger gate for upgrade-nudge popups
-- (storage / duration / seat thresholds). Every trigger MUST
-- come through here — none of them may decide to show a popup
-- on its own.
--
-- State lives in organisation.metadata.$.upgrade_nudge (JSON
-- home shared with $.over_limit — see org_over_limit_set):
--   plan       'free'|'team'|...   the plan the block was armed
--                                  against. The JS lib resets the
--                                  whole block when the org's
--                                  CURRENT plan differs ("once per
--                                  threshold ... until upgraded"),
--                                  so no webhook hook is needed and
--                                  a same-plan renewal re-arms
--                                  nothing.
--   fired      {trigger: epoch}    first time each threshold
--                                  crossed (history / debug)
--   seen       {trigger: {uid: epoch}}  which member has had
--                                  this threshold's popup —
--                                  "once per threshold, all
--                                  members", server-side, never
--                                  localStorage
--   last_shown {uid: 'YYYY-MM-DD'} the shared DAILY CAP — at
--                                  most one nudge popup per
--                                  member per day, whichever
--                                  trigger it came from
--
-- The caller (service/lib/upgrade-nudge.js) computes WHICH
-- triggers are currently true and asks for them in priority
-- order; this proc owns the atomic grant. Single UPDATE with
-- both guards in the WHERE clause, so two concurrent desk
-- boots of the same member can never both be granted
-- (ROW_COUNT() tells the winner). JSON_MERGE_PATCH deep-merges
-- the new leaf into the existing block, so parallel grants to
-- DIFFERENT members lose nothing.
--
-- Returns one row:
--   granted       1 = show the popup, 0 = suppressed
--   seen_already  this member already had this threshold →
--                 the caller may try its next candidate
--   capped_today  daily cap hit → the caller must STOP (no
--                 candidate can pass today)
-- =========================================================
DROP PROCEDURE IF EXISTS `org_upgrade_nudge_mark`$
CREATE PROCEDURE `org_upgrade_nudge_mark`(
  IN _org_id VARCHAR(16) CHARACTER SET ascii,
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

  UPDATE organisation
  SET metadata = JSON_MERGE_PATCH(
    IF(metadata IS NULL OR metadata = '' OR NOT JSON_VALID(metadata), '{}', metadata),
    JSON_OBJECT('upgrade_nudge', JSON_OBJECT(
      'plan', _plan,
      'fired', JSON_OBJECT(
        _trigger,
        -- keep the FIRST crossing time across re-grants to other members
        CAST(COALESCE(JSON_VALUE(metadata, _fired_path), UNIX_TIMESTAMP()) AS INTEGER)
      ),
      'seen', JSON_OBJECT(_trigger, JSON_OBJECT(_uid, UNIX_TIMESTAMP())),
      'last_shown', JSON_OBJECT(_uid, _day)
    ))
  )
  WHERE id = _org_id
    AND JSON_VALUE(metadata, _seen_path) IS NULL
    AND (JSON_VALUE(metadata, _cap_path) IS NULL
         OR JSON_VALUE(metadata, _cap_path) <> _day);

  SET _granted = IF(ROW_COUNT() > 0, 1, 0);

  SELECT
    _granted AS granted,
    IF(_granted = 1, 0,
       IF(JSON_VALUE(metadata, _seen_path) IS NOT NULL, 1, 0)) AS seen_already,
    IF(_granted = 1, 0,
       IF(JSON_VALUE(metadata, _cap_path) = _day, 1, 0)) AS capped_today
  FROM organisation WHERE id = _org_id;
END$

DELIMITER ;
