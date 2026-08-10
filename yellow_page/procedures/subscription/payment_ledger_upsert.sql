DELIMITER $

-- =========================================================
-- payment_ledger_upsert
--
-- THE ONLY WRITER of yp.payment_ledger. Two callers use it:
--   server-team service/public/stripe_webhook.js   (real time)
--   analytics-server bin/revenue-reconcile.js      (history + self-heal)
--
-- One proc rather than two INSERTs so there is exactly one definition of a
-- ledger row. Two hand-written copies is how the reconciled figure ends up
-- disagreeing with the live one and nobody can say which is right.
--
-- IDEMPOTENT on invoice_id. Both callers may see the same invoice — Stripe
-- re-delivers events, and the reconcile job deliberately replays history — so
-- a second call must update, never duplicate.
--
-- AMOUNTS ARE ALWAYS OVERWRITTEN. The caller has just read Stripe; the stored
-- row has not. This is what makes refunds work: charge.refunded re-reads the
-- invoice and calls this with the new amount_refunded.
--
-- PROVENANCE IS NOT DOWNGRADED. If a row was written by the webhook and the
-- reconcile job later touches it, source stays 'webhook' — that field answers
-- "did real-time work", and letting a nightly sweep erase the evidence would
-- destroy the only signal that the push path has broken.
--
-- IDENTITY FIELDS ARE NOT BLANKED. A caller with a partial view (an invoice
-- whose subscription metadata Stripe no longer returns) passes NULL rather
-- than a value; NULLIF/IFNULL keeps what is already stored instead of
-- replacing a known payer with nothing.
-- =========================================================
DROP PROCEDURE IF EXISTS `payment_ledger_upsert`$
CREATE PROCEDURE `payment_ledger_upsert`(
  IN _args JSON
)
BEGIN
  DECLARE _invoice_id      VARCHAR(64) DEFAULT NULL;
  DECLARE _subscription_id VARCHAR(64) DEFAULT NULL;
  DECLARE _customer_id     VARCHAR(64) DEFAULT NULL;
  DECLARE _entity_id       VARCHAR(16) DEFAULT NULL;
  DECLARE _payer_id        VARCHAR(16) DEFAULT NULL;
  DECLARE _email           VARCHAR(190) DEFAULT NULL;
  DECLARE _entity_type     VARCHAR(8)  DEFAULT 'user';
  DECLARE _plan            VARCHAR(30) DEFAULT 'team';
  DECLARE _period          VARCHAR(8)  DEFAULT 'month';
  DECLARE _amount_paid     BIGINT      DEFAULT 0;
  DECLARE _amount_refunded BIGINT      DEFAULT 0;
  DECLARE _currency        CHAR(3)     DEFAULT 'usd';
  DECLARE _billing_reason  VARCHAR(40) DEFAULT NULL;
  DECLARE _paid_at         INT(11) UNSIGNED DEFAULT 0;
  DECLARE _promo_code      VARCHAR(64) DEFAULT NULL;
  DECLARE _source          VARCHAR(16) DEFAULT 'webhook';
  DECLARE _existing        INT(11) UNSIGNED DEFAULT 0;

  SELECT JSON_VALUE(_args, "$.invoice_id")      INTO _invoice_id;
  SELECT JSON_VALUE(_args, "$.subscription_id") INTO _subscription_id;
  SELECT JSON_VALUE(_args, "$.customer_id")     INTO _customer_id;
  SELECT JSON_VALUE(_args, "$.entity_id")       INTO _entity_id;
  SELECT JSON_VALUE(_args, "$.payer_id")        INTO _payer_id;
  SELECT JSON_VALUE(_args, "$.email")           INTO _email;
  SELECT IFNULL(JSON_VALUE(_args, "$.entity_type"), 'user')  INTO _entity_type;
  SELECT IFNULL(JSON_VALUE(_args, "$.plan"), 'team')         INTO _plan;
  SELECT IFNULL(JSON_VALUE(_args, "$.period"), 'month')      INTO _period;
  SELECT IFNULL(JSON_VALUE(_args, "$.amount_paid"), 0)       INTO _amount_paid;
  SELECT IFNULL(JSON_VALUE(_args, "$.amount_refunded"), 0)   INTO _amount_refunded;
  SELECT LOWER(IFNULL(JSON_VALUE(_args, "$.currency"), 'usd')) INTO _currency;
  SELECT JSON_VALUE(_args, "$.billing_reason")  INTO _billing_reason;
  SELECT IFNULL(JSON_VALUE(_args, "$.paid_at"), UNIX_TIMESTAMP()) INTO _paid_at;
  SELECT JSON_VALUE(_args, "$.promo_code")      INTO _promo_code;
  SELECT IFNULL(JSON_VALUE(_args, "$.source"), 'webhook')    INTO _source;

  -- An invoice with no id is not a transaction. Answering with an empty result
  -- rather than raising keeps a malformed webhook from 500-ing back to Stripe,
  -- which would make it re-deliver the whole event forever.
  IF _invoice_id IS NULL OR _invoice_id = '' THEN
    SELECT NULL AS invoice_id, NULL AS sys_id, NULL AS net_amount, 0 AS was_insert
      FROM DUAL WHERE FALSE;
  ELSE
    -- entity_type and period are ENUMs in strict mode: an unexpected string
    -- would raise 1265 and kill the caller mid-webhook. Coerce here.
    IF _entity_type NOT IN ('user','org') THEN SET _entity_type = 'user'; END IF;
    IF _period NOT IN ('month','year')   THEN SET _period = 'month';     END IF;
    IF _source NOT IN ('webhook','reconcile') THEN SET _source = 'webhook'; END IF;

    SELECT COUNT(*) INTO _existing
      FROM yp.payment_ledger WHERE invoice_id = _invoice_id;

    INSERT INTO yp.payment_ledger
      (invoice_id, subscription_id, customer_id, entity_id, payer_id, email,
       entity_type, plan, period, amount_paid, amount_refunded, currency,
       billing_reason, paid_at, promo_code, source, ctime, mtime)
    VALUES
      (_invoice_id, _subscription_id, _customer_id, _entity_id, _payer_id, _email,
       _entity_type, _plan, _period, _amount_paid, _amount_refunded, _currency,
       _billing_reason, _paid_at, _promo_code, _source,
       UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
    ON DUPLICATE KEY UPDATE
      subscription_id = IFNULL(NULLIF(_subscription_id, ''), subscription_id),
      customer_id     = IFNULL(NULLIF(_customer_id, ''), customer_id),
      entity_id       = IFNULL(NULLIF(_entity_id, ''), entity_id),
      payer_id        = IFNULL(NULLIF(_payer_id, ''), payer_id),
      email           = IFNULL(NULLIF(_email, ''), email),
      entity_type     = _entity_type,
      plan            = _plan,
      period          = _period,
      amount_paid     = _amount_paid,
      amount_refunded = _amount_refunded,
      currency        = _currency,
      billing_reason  = IFNULL(NULLIF(_billing_reason, ''), billing_reason),
      paid_at         = _paid_at,
      promo_code      = IFNULL(NULLIF(_promo_code, ''), promo_code),
      -- See the header: a reconcile pass never erases webhook provenance.
      source          = IF(_source = 'reconcile' AND source = 'webhook', 'webhook', _source),
      mtime           = UNIX_TIMESTAMP();

    SELECT l.invoice_id, l.sys_id, l.net_amount,
           IF(_existing = 0, 1, 0) AS was_insert
      FROM yp.payment_ledger l WHERE l.invoice_id = _invoice_id;
  END IF;
END $

DELIMITER ;
