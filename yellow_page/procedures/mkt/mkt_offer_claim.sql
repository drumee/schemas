DELIMITER $

DROP PROCEDURE IF EXISTS `mkt_offer_claim`$
CREATE PROCEDURE `mkt_offer_claim`(
  IN _id          INT,
  IN _domain_key  VARCHAR(255),
  IN _fingerprint VARCHAR(64),
  IN _ttl_sec     INT
)
BEGIN
  -- Record on a pending redemption the company domain (at checkout) or the
  -- card fingerprint (once Stripe has collected it), and refuse if another
  -- live redemption of the same coupon already holds it.
  --
  -- The check and the write happen under one named lock. mkt_offer_check
  -- answers the same question read-only, but two shoppers using the same card
  -- at the same moment could both pass it before either wrote anything; here
  -- the second one waits for the first and then sees its row.
  --
  -- An empty argument is neither checked nor written, so the domain and the
  -- card are claimed by separate calls. Rules the coupon does not have
  -- (once_per_domain / once_per_card = 0) are not enforced, only recorded.
  DECLARE _cid INT UNSIGNED;
  DECLARE _em VARCHAR(255);
  DECLARE _once_domain TINYINT;
  DECLARE _once_card TINYINT;
  DECLARE _stale_before INT UNSIGNED;
  DECLARE _got INT;
  DECLARE _err VARCHAR(64) DEFAULT NULL;

  SET _ttl_sec = IFNULL(NULLIF(_ttl_sec, 0), 86400);
  SET _stale_before = UNIX_TIMESTAMP() - _ttl_sec;
  SET _domain_key = LOWER(IFNULL(_domain_key, ''));
  SET _fingerprint = IFNULL(_fingerprint, '');

  SELECT GET_LOCK('mkt_offer_claim', 10) INTO _got;
  IF IFNULL(_got, 0) <> 1 THEN
    SET _err = 'OFFER_BUSY';
  END IF;

  IF _err IS NULL THEN
    SELECT r.coupon_id, r.email, c.once_per_domain, c.once_per_card
      INTO _cid, _em, _once_domain, _once_card
      FROM mkt_coupon_redemption r
      INNER JOIN mkt_coupon c ON c.id = r.coupon_id
     WHERE r.id = _id AND r.status = 'pending';
    IF _cid IS NULL THEN
      SET _err = 'OFFER_HOLD_EXPIRED';
    END IF;
  END IF;

  IF _err IS NULL AND _once_domain = 1 AND _domain_key <> '' AND EXISTS (
       SELECT 1 FROM mkt_coupon_redemption
        WHERE coupon_id = _cid AND email_domain = _domain_key
          AND email <> _em AND id <> _id
          AND (status = 'confirmed'
               OR (status = 'pending' AND reserved_at >= _stale_before))
     ) THEN
    SET _err = 'OFFER_DOMAIN_USED';
  END IF;

  IF _err IS NULL AND _once_card = 1 AND _fingerprint <> '' AND EXISTS (
       SELECT 1 FROM mkt_coupon_redemption
        WHERE coupon_id = _cid AND card_fingerprint = _fingerprint
          AND id <> _id
          AND (status = 'confirmed'
               OR (status = 'pending' AND reserved_at >= _stale_before))
     ) THEN
    SET _err = 'OFFER_CARD_USED';
  END IF;

  IF _err IS NULL THEN
    UPDATE mkt_coupon_redemption
       SET email_domain = IF(_domain_key <> '', _domain_key, email_domain),
           card_fingerprint = IF(_fingerprint <> '', _fingerprint, card_fingerprint),
           mtime = UNIX_TIMESTAMP()
     WHERE id = _id;
  END IF;

  IF IFNULL(_got, 0) = 1 THEN
    DO RELEASE_LOCK('mkt_offer_claim');
  END IF;

  IF _err IS NOT NULL THEN
    SELECT _err AS error, _id AS id;
  ELSE
    SELECT id, coupon_id, email_domain, card_fingerprint, status
      FROM mkt_coupon_redemption WHERE id = _id;
  END IF;
END$

DELIMITER ;
