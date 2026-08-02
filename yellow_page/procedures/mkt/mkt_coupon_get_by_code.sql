DELIMITER $

-- =========================================================
-- mkt_coupon_get_by_code
-- =========================================================
DROP PROCEDURE IF EXISTS `mkt_coupon_get_by_code`$
CREATE PROCEDURE `mkt_coupon_get_by_code`(
  IN _code VARCHAR(64)
)
BEGIN
  SELECT c.*,
    (SELECT COUNT(*) FROM mkt_coupon_redemption r
      WHERE r.coupon_id = c.id AND r.status IN ('pending', 'confirmed')) AS used_count
  FROM mkt_coupon c
  WHERE c.code = UPPER(TRIM(_code))
  LIMIT 1;
END $

DELIMITER ;
