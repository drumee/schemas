DELIMITER $

DROP PROCEDURE IF EXISTS `mkt_offer_pending_get`$
CREATE PROCEDURE `mkt_offer_pending_get`(
  IN _uid VARCHAR(16)
)
BEGIN
  -- The offer code held for this account, if it can still be used: the
  -- coupon is live and this account has not already redeemed it. Once the
  -- purchase is confirmed the row simply stops answering, so nothing has to
  -- clear it.
  SELECT p.code, c.plan_scope, c.period_scope
    FROM mkt_offer_pending p
    INNER JOIN mkt_coupon c ON c.code = p.code
   WHERE p.uid = _uid
     AND c.active = 1
     AND (c.ends_at IS NULL OR c.ends_at = 0 OR c.ends_at >= UNIX_TIMESTAMP())
     AND NOT EXISTS (
       SELECT 1 FROM mkt_coupon_redemption r
        WHERE r.coupon_id = c.id AND r.uid = _uid AND r.status = 'confirmed'
     )
   LIMIT 1;
END$

DELIMITER ;
