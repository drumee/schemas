-- File: schemas/yellow_page/tables/mkt_mail_grant.sql
-- Purpose: ONE MAIL = ONE OFFER. A per-recipient grant for a coupon that was
--          mailed out, so a campaign link is worth exactly one run at the
--          discounted checkout, for exactly the person it was addressed to.
--
-- WHY A SERVER-SIDE ROW AT ALL. The CTA used to carry the coupon in the URL
-- (`promo=EMAILMKT270826_2`) with an FNV digest of the recipient beside it
-- (`for=cd8f5912`) checked only in the browser. Both are bearer credentials the
-- moment the mail lands: the code can be typed into the promo field by hand,
-- and the digest recomputed for any address. Nothing the client holds can
-- protect either.
--
-- The link now carries an opaque `token` and nothing else. It is worth nothing
-- without this table: the coupon code is returned by mkt_grant_claim, over an
-- authenticated call, only to the address this row names.
--
-- WHAT IT BUYS, precisely. mkt_coupon_redemption ALREADY enforces "1 email =
-- 1 live deal" across every partner code, so no single address could ever farm
-- multiple discounts. What was unbounded was the number of PEOPLE one mail
-- could serve: forward a 101-recipient campaign to a 50-person team and each
-- of them redeems a legitimate deal that was budgeted for one. That is the leak
-- this closes.
--
-- THE INVARIANT is uni_campaign_email. One grant per address per campaign,
-- forever. A resend ROTATES `token` on this row; it cannot make a second one.
-- "One mail = one flow" is therefore a property of the schema rather than of a
-- code path somebody can forget to call.
--
-- Collation: `email` is utf8mb4_general_ci to match mkt_coupon_redemption and
-- directory. Do not let it drift to unicode_ci -- cross-schema joins throw
-- ERROR 1267 when it does.
CREATE TABLE IF NOT EXISTS `mkt_mail_grant` (
  `id`          int(11) unsigned NOT NULL AUTO_INCREMENT,
  -- The utm_campaign the mail carried, e.g. 'segment-a-101-contacts'. Part of
  -- the unique key rather than a label: the same address may legitimately be
  -- offered a different campaign later, and that must be a different grant.
  `campaign`    varchar(64)  CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `coupon_id`   int(11) unsigned NOT NULL,
  -- Denormalised from mkt_coupon so the reserve/validate gate can match on
  -- (code, email) without a join, and so the row still says what was offered
  -- if the coupon is later renamed.
  `code`        varchar(64)  CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `email`       varchar(255) NOT NULL,
  -- Filled at issue time when the sender knows it (the promo dashboard sends
  -- to rows that carry a payer_id), otherwise stamped by the first claim.
  -- NOT the identity the claim is checked against -- see mkt_grant_claim.
  `uid`         varchar(16)  CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  -- 32 hex. The only thing that travels in the mail.
  `token`       char(32)     CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `status`      enum('issued','claimed','revoked') NOT NULL DEFAULT 'issued',
  -- 1 = the link is spent by its first successful claim, even for the person
  -- it names; they must ask for a resend to get another. 0 = re-claims by that
  -- same person are free (they opened checkout, went to find their card, came
  -- back).
  --
  -- DEFAULT 1, because that is what the campaign asked for: click, sign in,
  -- billing opens; sign out, click again, sign in again, nothing happens. A
  -- campaign that wants the forgiving behaviour opts out explicitly.
  --
  -- Either way the identity check is unchanged -- this governs HOW MANY TIMES,
  -- never WHO.
  `single_use`  tinyint(1)   NOT NULL DEFAULT 1,
  -- Includes the original send, so the first issue leaves this at 1.
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
  -- THE invariant. See the header.
  UNIQUE KEY `uni_campaign_email` (`campaign`, `email`),
  UNIQUE KEY `uni_token` (`token`),
  -- The reserve/validate gate: "is there a claimed grant for this code and
  -- this address?"
  KEY `idx_code_email` (`code`, `email`, `status`),
  KEY `idx_campaign_status` (`campaign`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='One mail = one offer — per-recipient grant for a mailed coupon'
