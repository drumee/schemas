DELIMITER $

-- =========================================================
-- mkt_coupon_stats
-- Aggregate for analytics Coupons panel header.
-- =========================================================
DROP PROCEDURE IF EXISTS `mkt_coupon_stats`$
CREATE PROCEDURE `mkt_coupon_stats`()
BEGIN
  SELECT
    (SELECT COUNT(*) FROM mkt_coupon) AS coupons_total,
    (SELECT COUNT(*) FROM mkt_coupon WHERE active = 1
      AND (ends_at IS NULL OR ends_at > UNIX_TIMESTAMP())) AS coupons_active,
    (SELECT COUNT(*) FROM mkt_coupon WHERE active = 0) AS coupons_inactive,
    (SELECT COUNT(*) FROM mkt_coupon_redemption WHERE status = 'confirmed') AS redemptions_confirmed,
    (SELECT COUNT(*) FROM mkt_coupon_redemption WHERE status = 'pending') AS redemptions_pending,
    (SELECT COUNT(*) FROM mkt_coupon_redemption WHERE status = 'released') AS redemptions_released,
    (SELECT COUNT(*) FROM mkt_coupon_redemption WHERE status = 'failed') AS redemptions_failed,
    (SELECT COUNT(DISTINCT email) FROM mkt_coupon_redemption WHERE status = 'confirmed') AS unique_emails,
    (SELECT COUNT(DISTINCT partner) FROM mkt_coupon WHERE partner <> '') AS partners,
    (SELECT COUNT(*) FROM mkt_coupon_redemption
      WHERE status = 'confirmed' AND confirmed_at >= UNIX_TIMESTAMP() - 7 * 86400) AS confirmed_7d,
    (SELECT COUNT(*) FROM mkt_coupon_redemption
      WHERE status = 'confirmed' AND confirmed_at >= UNIX_TIMESTAMP() - 30 * 86400) AS confirmed_30d;
END $

DELIMITER ;
