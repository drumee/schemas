-- Offer rules for MKT coupons (TEAM1: first month $1, then list price).
--
-- Until now a coupon could only express "N% off for M cycles" plus free days,
-- and the only anti-abuse rule was "1 email = 1 live deal". TEAM1 needs a
-- fixed price for the first cycle and a stricter eligibility set, so the
-- coupon row grows one column per rule. Every default reproduces today's
-- behaviour, so the live coupons are untouched by this patch:
--
--   amount_off        fixed discount in minor units (cents); NULL = use
--                     percent_off. Stripe takes one or the other, never both.
--   period_scope      'all' | 'month' | 'year' — billing cycle the code is for
--   new_only          only a payer whose account / workspace has never paid
--   once_per_card     one redemption per card (Stripe card fingerprint)
--   once_per_domain   one redemption per company email domain (free-mail
--                     addresses count per address, see service/lib/offer-email)
--   block_disposable  refuse throwaway email domains
--   exclusive         not combinable with Reward Hub / LAUNCH30
--
-- The redemption keeps what the rules were checked against, so the next
-- shopper can be compared with it:
--
--   email_domain      company domain of the redeeming email ('' for free-mail)
--   card_fingerprint  Stripe card.fingerprint of the card that paid
ALTER TABLE `mkt_coupon`
  ADD COLUMN IF NOT EXISTS `amount_off` int(11) unsigned DEFAULT NULL
    COMMENT 'Fixed discount in minor units; NULL = percent_off' AFTER `percent_off`,
  ADD COLUMN IF NOT EXISTS `period_scope` varchar(16)
    CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'all'
    COMMENT "'all' | 'month' | 'year'" AFTER `plan_scope`,
  ADD COLUMN IF NOT EXISTS `new_only` tinyint(1) NOT NULL DEFAULT 0
    COMMENT 'Only a payer/workspace that never paid' AFTER `max_redemptions`,
  ADD COLUMN IF NOT EXISTS `once_per_card` tinyint(1) NOT NULL DEFAULT 0
    COMMENT 'One redemption per card fingerprint' AFTER `new_only`,
  ADD COLUMN IF NOT EXISTS `once_per_domain` tinyint(1) NOT NULL DEFAULT 0
    COMMENT 'One redemption per company email domain' AFTER `once_per_card`,
  ADD COLUMN IF NOT EXISTS `block_disposable` tinyint(1) NOT NULL DEFAULT 0
    COMMENT 'Refuse disposable email domains' AFTER `once_per_domain`,
  ADD COLUMN IF NOT EXISTS `exclusive` tinyint(1) NOT NULL DEFAULT 0
    COMMENT 'Not combinable with Reward Hub / LAUNCH30' AFTER `block_disposable`;

ALTER TABLE `mkt_coupon_redemption`
  ADD COLUMN IF NOT EXISTS `email_domain` varchar(255)
    CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL
    COMMENT "Company domain checked by once_per_domain; '' = free-mail" AFTER `email`,
  ADD COLUMN IF NOT EXISTS `card_fingerprint` varchar(64)
    CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL
    COMMENT 'Stripe card.fingerprint checked by once_per_card' AFTER `email_domain`;

ALTER TABLE `mkt_coupon_redemption`
  ADD INDEX IF NOT EXISTS `idx_coupon_domain` (`coupon_id`, `email_domain`),
  ADD INDEX IF NOT EXISTS `idx_coupon_card` (`coupon_id`, `card_fingerprint`);
