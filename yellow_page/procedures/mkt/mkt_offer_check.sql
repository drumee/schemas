DELIMITER $

DROP PROCEDURE IF EXISTS `mkt_offer_check`$
CREATE PROCEDURE `mkt_offer_check`(
  IN _code        VARCHAR(64),
  IN _uid         VARCHAR(16),
  IN _email       VARCHAR(255),
  IN _period      VARCHAR(16),
  IN _domain_key  VARCHAR(255),
  IN _fingerprint VARCHAR(64),
  IN _exclude_id  INT,
  IN _ttl_sec     INT
)
BEGIN
  -- The offer rules of an MKT coupon (add_offer_rules_to_mkt_coupon), on top
  -- of what mkt_coupon_validate / mkt_coupon_reserve already enforce (active,
  -- ends_at, plan_scope, 1 email = 1 deal, max_redemptions). Read-only: the
  -- checkout calls it after reserve with _exclude_id = the reserved row, the
  -- preview with 0, and the card step again once the card is known.
  --
  -- A coupon with none of the rules set answers OK with its fields, so the
  -- caller can run this for every code. _domain_key is '' for a free-mail
  -- address (the caller decides which domains are free-mail), and then the
  -- domain rule is left to the per-email rule.
  DECLARE _cid INT UNSIGNED;
  DECLARE _period_scope VARCHAR(16);
  DECLARE _new_only TINYINT;
  DECLARE _once_card TINYINT;
  DECLARE _once_domain TINYINT;
  DECLARE _exclusive TINYINT;
  DECLARE _em VARCHAR(255);
  DECLARE _stale_before INT UNSIGNED;
  DECLARE _err VARCHAR(64) DEFAULT NULL;

  SET _em = LOWER(TRIM(IFNULL(_email, '')));
  SET _ttl_sec = IFNULL(NULLIF(_ttl_sec, 0), 86400);
  SET _stale_before = UNIX_TIMESTAMP() - _ttl_sec;
  SET _exclude_id = IFNULL(_exclude_id, 0);

  SELECT id, LOWER(period_scope), new_only, once_per_card, once_per_domain, exclusive
    INTO _cid, _period_scope, _new_only, _once_card, _once_domain, _exclusive
    FROM mkt_coupon WHERE code = UPPER(TRIM(_code)) LIMIT 1;

  IF _cid IS NULL THEN
    SET _err = 'CODE_NOT_FOUND';
  END IF;

  -- Already redeemed by this email. mkt_coupon_validate only refuses an email
  -- holding a DIFFERENT code, and new_only only sees the purchase once the
  -- webhook has recorded it — so right after paying, a preview still said OK.
  -- mkt_coupon_reserve refuses this case too; this makes the preview agree.
  IF _err IS NULL AND _em <> '' AND EXISTS (
       SELECT 1 FROM mkt_coupon_redemption
        WHERE coupon_id = _cid AND email = _em AND status = 'confirmed'
          AND id <> _exclude_id
     ) THEN
    SET _err = 'EMAIL_ALREADY_USED';
  END IF;

  IF _err IS NULL AND _period_scope NOT IN ('', 'all')
     AND _period_scope <> LOWER(TRIM(IFNULL(_period, ''))) THEN
    SET _err = 'COUPON_PERIOD_MISMATCH';
  END IF;

  -- Never paid: no paid invoice and no Stripe subscription, for the payer
  -- or for the organisation they own.
  IF _err IS NULL AND _new_only = 1 AND (
       EXISTS (
         SELECT 1 FROM payment_ledger
          WHERE amount_paid > 0
            AND (payer_id = _uid OR entity_id = _uid
                 OR entity_id IN (SELECT id FROM organisation WHERE owner_id = _uid))
       )
       OR EXISTS (
         SELECT 1 FROM subscription_new
          WHERE IFNULL(subscription_id, '') <> ''
            AND (entity_id = _uid
                 OR entity_id IN (SELECT id FROM organisation WHERE owner_id = _uid))
       )
     ) THEN
    SET _err = 'OFFER_NOT_NEW_WORKSPACE';
  END IF;

  -- Not combinable: a LAUNCH30 trial running, or a Reward Hub prize won.
  IF _err IS NULL AND _exclusive = 1 AND (
       EXISTS (SELECT 1 FROM promo_launch30 WHERE payer_id = _uid AND status = 'claimed')
       OR EXISTS (SELECT 1 FROM reward_claim WHERE uid = _uid AND completed_count > 0)
     ) THEN
    SET _err = 'OFFER_NOT_COMBINABLE';
  END IF;

  IF _err IS NULL AND _once_domain = 1 AND IFNULL(_domain_key, '') <> '' AND EXISTS (
       SELECT 1 FROM mkt_coupon_redemption
        WHERE coupon_id = _cid
          AND email_domain = LOWER(_domain_key)
          AND email <> _em
          AND id <> _exclude_id
          AND (status = 'confirmed'
               OR (status = 'pending' AND reserved_at >= _stale_before))
     ) THEN
    SET _err = 'OFFER_DOMAIN_USED';
  END IF;

  IF _err IS NULL AND _once_card = 1 AND IFNULL(_fingerprint, '') <> '' AND EXISTS (
       SELECT 1 FROM mkt_coupon_redemption
        WHERE coupon_id = _cid
          AND card_fingerprint = _fingerprint
          AND id <> _exclude_id
          AND (status = 'confirmed'
               OR (status = 'pending' AND reserved_at >= _stale_before))
     ) THEN
    SET _err = 'OFFER_CARD_USED';
  END IF;

  IF _err IS NOT NULL THEN
    SELECT _err AS error, UPPER(TRIM(_code)) AS code;
  ELSE
    SELECT code, plan_scope, period_scope, percent_off, amount_off,
           duration_months, trial_days, new_only, once_per_card,
           once_per_domain, block_disposable, exclusive
      FROM mkt_coupon WHERE id = _cid;
  END IF;
END$

DELIMITER ;
