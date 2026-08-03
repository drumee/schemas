DELIMITER $

-- =========================================================
-- mkt_coupon_confirm
-- Mark pending redemption confirmed after Stripe paid.
-- =========================================================
DROP PROCEDURE IF EXISTS `mkt_coupon_confirm`$
CREATE PROCEDURE `mkt_coupon_confirm`(
  IN _session_id       VARCHAR(128),
  IN _subscription_id  VARCHAR(128),
  IN _uid              VARCHAR(16),
  IN _email            VARCHAR(255)
)
BEGIN
  DECLARE _now INT UNSIGNED;
  SET _now = UNIX_TIMESTAMP();

  UPDATE mkt_coupon_redemption
     SET status = 'confirmed',
         confirmed_at = _now,
         stripe_subscription_id = NULLIF(_subscription_id, ''),
         uid = IFNULL(NULLIF(_uid, ''), uid),
         email = IFNULL(NULLIF(LOWER(TRIM(_email)), ''), email),
         mtime = _now
   WHERE status = 'pending'
     AND (
       (NULLIF(_session_id, '') IS NOT NULL AND stripe_session_id = _session_id)
       OR (NULLIF(_email, '') IS NOT NULL AND email = LOWER(TRIM(_email)) AND uid = _uid)
     )
   ORDER BY id DESC
   LIMIT 1;

  SELECT * FROM mkt_coupon_redemption
   WHERE (NULLIF(_session_id, '') IS NOT NULL AND stripe_session_id = _session_id)
      OR (status = 'confirmed' AND email = LOWER(TRIM(_email)) AND uid = _uid)
   ORDER BY id DESC
   LIMIT 1;
END $

DELIMITER ;
