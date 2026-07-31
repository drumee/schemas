DELIMITER $
DROP PROCEDURE IF EXISTS `payment_get_subscription`$
CREATE PROCEDURE `payment_get_subscription`(
  IN _entity_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  SELECT s.entity_id, s.subscription_id, s.customer_id, s.plan, s.period, s.recurring,
         s.price, s.offer_price, s.status, s.ctime,
         q.plan AS entitlement_plan, JSON_VALUE(q.quota,'$.disk') AS disk_limit,
         JSON_VALUE(q.quota,'$.seat') AS seats,
         JSON_VALUE(q.quota,'$.organization') AS organization,
         q.period_end
  FROM yp.subscription_new s
  -- An EXPIRED claim-reward entitlement joins as NULL, so the billing screen
  -- reports no entitlement rather than a lapsed one. A rewarded user who
  -- subscribes has this row overwritten with source='stripe', and cancelling
  -- re-materialises the reward (payment_clear_entitlement), so a subscriber CAN
  -- legitimately be sitting on a reward row here — and after 5 years it would
  -- otherwise still read `reward-5y` with a 2^63-1 disk_limit on the billing
  -- page while enforcement had already dropped them to the free tier.
  --
  -- Scoped to source='reward': a Stripe row's own period_end is informational
  -- (cancellation DELETEs the row), so filtering on it here would blank the
  -- entitlement of a live subscriber whose renewal webhook was merely late.
  LEFT JOIN yp.quota q
         ON q.payer_id = s.entity_id
        AND (IFNULL(q.source, 'free') <> 'reward'
             OR IFNULL(q.period_end, 0) = 0
             OR q.period_end > UNIX_TIMESTAMP())
  WHERE s.entity_id = _entity_id;
END $
DELIMITER ;
