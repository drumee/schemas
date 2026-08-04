DELIMITER $

-- =========================================================
-- mkt_coupon_bind_session
-- Attach Stripe checkout session id to a pending redemption.
-- =========================================================
DROP PROCEDURE IF EXISTS `mkt_coupon_bind_session`$
CREATE PROCEDURE `mkt_coupon_bind_session`(
  IN _redemption_id INT,
  IN _session_id    VARCHAR(128)
)
BEGIN
  UPDATE mkt_coupon_redemption
     SET stripe_session_id = _session_id, mtime = UNIX_TIMESTAMP()
   WHERE id = _redemption_id AND status = 'pending';
  SELECT * FROM mkt_coupon_redemption WHERE id = _redemption_id;
END $

DELIMITER ;
