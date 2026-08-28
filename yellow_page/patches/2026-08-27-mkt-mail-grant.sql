-- =========================================================
-- One mail = one offer.
--
-- Creates yp.mkt_mail_grant and adds mkt_coupon.requires_grant.
--
-- WHAT WAS WRONG. The segment campaign CTA carried the coupon
-- in the URL:
--
--   #/desk/billing?plan=team&cycle=monthly&tab=checkout
--                 &promo=EMAILMKT270826_2&for=cd8f5912
--
-- `promo` is the live code, in cleartext, in every inbox it
-- reached. `for` is FNV-1a of the recipient's address, checked
-- only in the browser and recomputable for any address in four
-- lines of JavaScript. Both source files that build it already
-- say so in their own comments ("A UX GUARD, NOT A SECURITY
-- CONTROL... If the code itself must be restricted, that
-- belongs in the proc, not in a URL"). This is that proc.
--
-- WHAT WAS ALREADY FINE, and it narrows the fix. Reserve
-- enforces "1 email = 1 live deal" across every partner code,
-- so one person could never farm several discounts however
-- they abused the link. The unbounded quantity was PEOPLE: a
-- mail forwarded to a 50-strong team yields 50 legitimate
-- deals against a budget of one.
--
-- TWO OBJECTS, AND ONLY ONE OF THEM CHANGES BEHAVIOUR TODAY.
--
--   mkt_mail_grant          new table, nothing reads it yet.
--   mkt_coupon.requires_grant  DEFAULT 0 -- every existing code
--                           keeps behaving exactly as it does
--                           now. Reserve and validate grow a
--                           gate that is inert until a code
--                           opts in.
--
-- That default is what makes this patch safe to apply ahead of
-- the services. EMAILMKT270826_2 stays at 0: its value is
-- already public in 203 inboxes and 203 links are already in
-- flight, so gating it now would strand real recipients. Mint a
-- NEW code with requires_grant = 1 for grant-gated sends and
-- let the old one age out.
--
-- ORDER MATTERS, the same way it did for oauth_state.dest: the
-- table and the column must exist BEFORE analytics-server mints
-- its first token, or the send fails per address and the
-- campaign goes out with dead CTAs -- which reads to the
-- recipient as the offer being withdrawn.
--
-- Both statements are replay-safe (IF NOT EXISTS).
-- =========================================================

CREATE TABLE IF NOT EXISTS `mkt_mail_grant` (
  `id`          int(11) unsigned NOT NULL AUTO_INCREMENT,
  `campaign`    varchar(64)  CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `coupon_id`   int(11) unsigned NOT NULL,
  `code`        varchar(64)  CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `email`       varchar(255) NOT NULL,
  `uid`         varchar(16)  CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `token`       char(32)     CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `status`      enum('issued','claimed','revoked') NOT NULL DEFAULT 'issued',
  `single_use`  tinyint(1)   NOT NULL DEFAULT 1,
  `send_count`  smallint(5) unsigned NOT NULL DEFAULT 1,
  `claim_count` smallint(5) unsigned NOT NULL DEFAULT 0,
  `issued_at`   int(11) unsigned NOT NULL,
  `expires_at`  int(11) unsigned NOT NULL,
  `last_sent_at`   int(11) unsigned NOT NULL,
  `first_claim_at` int(11) unsigned DEFAULT NULL,
  `last_claim_at`  int(11) unsigned DEFAULT NULL,
  `ctime`       int(11) unsigned NOT NULL,
  `mtime`       int(11) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uni_campaign_email` (`campaign`, `email`),
  UNIQUE KEY `uni_token` (`token`),
  KEY `idx_code_email` (`code`, `email`, `status`),
  KEY `idx_campaign_status` (`campaign`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='One mail = one offer — per-recipient grant for a mailed coupon';

ALTER TABLE `mkt_coupon`
  ADD COLUMN IF NOT EXISTS `requires_grant` tinyint(1) NOT NULL DEFAULT 0
    COMMENT '1 = redeemable only with a claimed mkt_mail_grant for (code,email)'
    AFTER `max_redemptions`;
