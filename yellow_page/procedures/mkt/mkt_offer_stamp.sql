DELIMITER $

DROP PROCEDURE IF EXISTS `mkt_offer_stamp`$
CREATE PROCEDURE `mkt_offer_stamp`(
  IN _id          INT,
  IN _domain_key  VARCHAR(255),
  IN _fingerprint VARCHAR(64)
)
BEGIN
  -- Record on a pending redemption what mkt_offer_check compared it against,
  -- so the next shopper on the same company domain / card is refused. An
  -- empty argument leaves the column as it is (the domain is stamped at
  -- checkout, the card later, once Stripe has collected it).
  UPDATE mkt_coupon_redemption
     SET email_domain = IFNULL(NULLIF(_domain_key, ''), email_domain),
         card_fingerprint = IFNULL(NULLIF(_fingerprint, ''), card_fingerprint),
         mtime = UNIX_TIMESTAMP()
   WHERE id = _id AND status = 'pending';
  SELECT * FROM mkt_coupon_redemption WHERE id = _id;
END$

DELIMITER ;
