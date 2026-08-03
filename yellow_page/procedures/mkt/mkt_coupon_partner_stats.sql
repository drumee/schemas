DELIMITER $

-- =========================================================
-- mkt_coupon_partner_stats
-- Per-partner redemption breakdown for analytics Coupons panel.
-- =========================================================
DROP PROCEDURE IF EXISTS `mkt_coupon_partner_stats`$
CREATE PROCEDURE `mkt_coupon_partner_stats`()
BEGIN
  SELECT
    IFNULL(NULLIF(c.partner, ''), '(none)') AS partner,
    COUNT(DISTINCT c.id) AS coupons,
    SUM(CASE WHEN r.status = 'confirmed' THEN 1 ELSE 0 END) AS confirmed,
    SUM(CASE WHEN r.status = 'pending' THEN 1 ELSE 0 END) AS pending,
    COUNT(DISTINCT CASE WHEN r.status = 'confirmed' THEN r.email END) AS unique_emails
  FROM mkt_coupon c
  LEFT JOIN mkt_coupon_redemption r ON r.coupon_id = c.id
  GROUP BY IFNULL(NULLIF(c.partner, ''), '(none)')
  ORDER BY confirmed DESC, partner ASC;
END $

DELIMITER ;
