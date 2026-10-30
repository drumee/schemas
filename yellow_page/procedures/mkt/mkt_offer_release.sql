DELIMITER $

DROP PROCEDURE IF EXISTS `mkt_offer_release`$
CREATE PROCEDURE `mkt_offer_release`(
  IN _id INT
)
BEGIN
  -- Give back a pending hold the offer rules refused after reserve (e.g. the
  -- card turned out to have used the offer already), so it neither blocks the
  -- shopper's email for the TTL nor counts against the domain.
  UPDATE mkt_coupon_redemption
     SET status = 'released', mtime = UNIX_TIMESTAMP()
   WHERE id = _id AND status = 'pending';
  SELECT * FROM mkt_coupon_redemption WHERE id = _id;
END$

DELIMITER ;
