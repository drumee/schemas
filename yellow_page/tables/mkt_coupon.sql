-- File: schemas/yellow_page/tables/mkt_coupon.sql
-- Purpose: MKT outreach promo codes (KOL / partners). First-party codes
--          tracked in YP; Stripe Coupon is created lazily at checkout and
--          referenced by stripe_coupon_id. Phase A = kind 'kol_discount'
--          (trial_days free + percent_off for duration_months).
CREATE TABLE IF NOT EXISTS `mkt_coupon` (
  `id`                int(11) unsigned NOT NULL AUTO_INCREMENT,
  `code`              varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `partner`           varchar(128) NOT NULL DEFAULT '' COMMENT 'Iris, Theo, …',
  `kind`              varchar(32) NOT NULL DEFAULT 'kol_discount'
                      COMMENT 'kol_discount | warm_trial | b2b_pilot',
  -- 'all' = any plan checkout supports (today team|business); otherwise a
  -- single yp.plan.plan_code the code is restricted to. Single value, not a
  -- set: the product rule is "one plan or all plans".
  `plan_scope`        varchar(32) CHARACTER SET ascii COLLATE ascii_general_ci
                      NOT NULL DEFAULT 'all'
                      COMMENT "'all' or a single yp.plan.plan_code",
  `percent_off`       tinyint(3) unsigned NOT NULL DEFAULT 50,
  `duration_months`   tinyint(3) unsigned NOT NULL DEFAULT 3
                      COMMENT 'Stripe repeating coupon length (billing cycles after trial)',
  `trial_days`        smallint(5) unsigned NOT NULL DEFAULT 30,
  `stripe_coupon_id`  varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `active`            tinyint(1) NOT NULL DEFAULT 1,
  `ends_at`           int(11) unsigned DEFAULT NULL COMMENT 'UNIX; NULL = no hard end',
  `max_redemptions`   int(11) unsigned DEFAULT NULL COMMENT 'NULL = unlimited',
  -- 1 = this code is redeemable ONLY by someone holding a claimed
  -- mkt_mail_grant for (code, email). The server-side recipient allowlist the
  -- mailed-CTA campaigns need: without it the code is a bearer credential the
  -- moment the mail lands, because the promo field accepts it typed by hand.
  --
  -- DEFAULT 0 so every code that predates grants behaves exactly as before.
  -- Enforced in BOTH mkt_coupon_reserve and mkt_coupon_validate, in the same
  -- position -- the two must not drift, or Apply green-lights what Proceed
  -- then refuses.
  `requires_grant`    tinyint(1) NOT NULL DEFAULT 0
                      COMMENT '1 = needs a claimed mkt_mail_grant for (code,email)',
  `notes`             varchar(512) DEFAULT NULL,
  `created_by`        varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `ctime`             int(11) unsigned NOT NULL,
  `mtime`             int(11) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uni_code` (`code`),
  KEY `idx_active_ends` (`active`, `ends_at`),
  KEY `idx_partner` (`partner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='MKT outreach coupons — source of truth for partner promo codes'
