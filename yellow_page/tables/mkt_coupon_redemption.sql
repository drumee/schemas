-- File: schemas/yellow_page/tables/mkt_coupon_redemption.sql
-- Purpose: Track which email applied which MKT coupon. Anti-cheat: UNIQUE
--          on email across the whole table for pending|confirmed so one
--          address cannot burn multiple partner codes. Pending rows older
--          than the reserve TTL are releasable (abandoned checkout).
CREATE TABLE IF NOT EXISTS `mkt_coupon_redemption` (
  `id`                 int(11) unsigned NOT NULL AUTO_INCREMENT,
  `coupon_id`          int(11) unsigned NOT NULL,
  `code`               varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `partner`            varchar(128) NOT NULL DEFAULT '',
  `email`              varchar(255) NOT NULL,
  `uid`                varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `plan`               varchar(32) DEFAULT NULL,
  `period`             varchar(16) DEFAULT NULL,
  `entity_type`        varchar(16) DEFAULT NULL,
  `stripe_session_id`  varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `stripe_subscription_id` varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `status`             enum('pending','confirmed','failed','released') NOT NULL DEFAULT 'pending',
  `reserved_at`        int(11) unsigned NOT NULL,
  `confirmed_at`       int(11) unsigned DEFAULT NULL,
  `ctime`              int(11) unsigned NOT NULL,
  `mtime`              int(11) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  -- Anti-cheat (1 email = 1 live deal) is enforced in mkt_coupon_reserve:
  -- no second pending|confirmed row for the same email. released/failed
  -- rows are historical and may share an email. Session id is unique when set.
  UNIQUE KEY `uni_stripe_session` (`stripe_session_id`),
  KEY `idx_email_status` (`email`, `status`),
  KEY `idx_coupon` (`coupon_id`),
  KEY `idx_code` (`code`),
  KEY `idx_status_reserved` (`status`, `reserved_at`),
  KEY `idx_uid` (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='MKT coupon redemptions — email↔code tracking for outreach'
