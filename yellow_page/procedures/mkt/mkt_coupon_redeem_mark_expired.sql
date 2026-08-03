DELIMITER $

-- =========================================================
-- mkt_coupon_redeem_mark_expired
-- Close out a direct redemption after the worker has cleared its
-- entitlement. Separate from the clear so the worker can revert the quota
-- first and only then record it — if the process dies in between, the row
-- stays 'confirmed' and the job simply retries, rather than being marked
-- done with the entitlement still live.
--
-- Frees the email as well: the "1 email = 1 live deal" rule counts
-- confirmed rows, so a lapsed grant must stop blocking the next code.
-- =========================================================
DROP PROCEDURE IF EXISTS `mkt_coupon_redeem_mark_expired`$
CREATE PROCEDURE `mkt_coupon_redeem_mark_expired`(
  IN _id INT
)
BEGIN
  UPDATE mkt_coupon_redemption
     SET status = 'expired', mtime = UNIX_TIMESTAMP()
   WHERE id = _id AND status = 'confirmed';
  SELECT id, code, email, status, trial_ends_at
  FROM mkt_coupon_redemption WHERE id = _id LIMIT 1;
END $

DELIMITER ;
