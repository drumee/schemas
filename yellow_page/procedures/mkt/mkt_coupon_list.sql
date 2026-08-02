DELIMITER $

-- =========================================================
-- mkt_coupon_list
-- =========================================================
DROP PROCEDURE IF EXISTS `mkt_coupon_list`$
CREATE PROCEDURE `mkt_coupon_list`(
  IN _q VARCHAR(128)
)
BEGIN
  SELECT
    c.*,
    -- Alias: List.Smart itemsOpt.kind overwrites c.kind with the widget name.
    c.kind AS coupon_kind,
    (SELECT COUNT(*) FROM mkt_coupon_redemption r
      WHERE r.coupon_id = c.id AND r.status = 'confirmed') AS confirmed_count,
    (SELECT COUNT(*) FROM mkt_coupon_redemption r
      WHERE r.coupon_id = c.id AND r.status = 'pending') AS pending_count,
    (SELECT COUNT(*) FROM mkt_coupon_redemption r
      WHERE r.coupon_id = c.id AND r.status = 'released') AS released_count,
    (SELECT COUNT(*) FROM mkt_coupon_redemption r
      WHERE r.coupon_id = c.id AND r.status = 'failed') AS failed_count,
    (SELECT COUNT(DISTINCT r.email) FROM mkt_coupon_redemption r
      WHERE r.coupon_id = c.id AND r.status = 'confirmed') AS unique_emails
  FROM mkt_coupon c
  WHERE _q IS NULL OR _q = ''
     OR c.code LIKE CONCAT('%', UPPER(_q), '%')
     OR c.partner LIKE CONCAT('%', _q, '%')
  ORDER BY c.ctime DESC;
END $

DELIMITER ;
