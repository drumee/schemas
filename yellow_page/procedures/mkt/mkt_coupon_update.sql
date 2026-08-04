DELIMITER $

-- =========================================================
-- mkt_coupon_update
-- Soft fields only — code is immutable once created (redemption history).
-- =========================================================
DROP PROCEDURE IF EXISTS `mkt_coupon_update`$
CREATE PROCEDURE `mkt_coupon_update`(
  IN _id               INT,
  IN _partner          VARCHAR(128),
  IN _percent_off      INT,
  IN _duration_months  INT,
  IN _trial_days       INT,
  IN _active           INT,
  IN _ends_at          INT,
  IN _max_redemptions  INT,
  IN _notes            VARCHAR(512),
  IN _stripe_coupon_id VARCHAR(64),
  IN _plan_scope       VARCHAR(32)
)
BEGIN
  SET _plan_scope = LOWER(NULLIF(TRIM(IFNULL(_plan_scope, '')), ''));

  IF NOT EXISTS (SELECT 1 FROM mkt_coupon WHERE id = _id) THEN
    SELECT 'NOT_FOUND' AS error;
  -- Same guard as create: never let an unsellable plan_code be stored.
  ELSEIF _plan_scope IS NOT NULL AND _plan_scope <> 'all'
     AND NOT EXISTS (SELECT 1 FROM yp.plan WHERE plan_code = _plan_scope) THEN
    SELECT 'PLAN_SCOPE_INVALID' AS error, _plan_scope AS plan_scope;
  ELSE
    UPDATE mkt_coupon SET
      partner = IFNULL(TRIM(_partner), partner),
      percent_off = IFNULL(NULLIF(_percent_off, 0), percent_off),
      duration_months = IFNULL(NULLIF(_duration_months, 0), duration_months),
      trial_days = IFNULL(_trial_days, trial_days),
      active = IF(_active IS NULL, active, IF(_active = 0, 0, 1)),
      ends_at = CASE
        WHEN _ends_at IS NULL THEN ends_at
        WHEN _ends_at = 0 THEN NULL
        ELSE _ends_at
      END,
      max_redemptions = CASE
        WHEN _max_redemptions IS NULL THEN max_redemptions
        WHEN _max_redemptions = 0 THEN NULL
        ELSE _max_redemptions
      END,
      notes = IFNULL(_notes, notes),
      stripe_coupon_id = IFNULL(NULLIF(TRIM(_stripe_coupon_id), ''), stripe_coupon_id),
      plan_scope = IFNULL(_plan_scope, plan_scope),
      mtime = UNIX_TIMESTAMP()
    WHERE id = _id;
    SELECT * FROM mkt_coupon WHERE id = _id;
  END IF;
END $

DELIMITER ;
