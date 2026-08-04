DELIMITER $

-- =========================================================
-- mkt_coupon_set_stripe_id
-- =========================================================
DROP PROCEDURE IF EXISTS `mkt_coupon_set_stripe_id`$
CREATE PROCEDURE `mkt_coupon_set_stripe_id`(
  IN _id               INT,
  IN _stripe_coupon_id VARCHAR(64)
)
BEGIN
  UPDATE mkt_coupon
     SET stripe_coupon_id = _stripe_coupon_id, mtime = UNIX_TIMESTAMP()
   WHERE id = _id;
  SELECT * FROM mkt_coupon WHERE id = _id;
END $

DELIMITER ;