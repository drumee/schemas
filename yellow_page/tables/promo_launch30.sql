-- File: schemas/yellow_page/tables/promo_launch30.sql
-- Purpose: LAUNCH30 promo — "Start your 1-month Team Plan today", claimed
--          with no card and no Stripe object at all (design doc 2026-07-30).
--          One row per PAYER (the individual who claimed), tracking eligibility
--          ("seen" flags, so a modal shown once never re-shows on any device —
--          the doc explicitly calls out localStorage as the wrong place for
--          this) and the claim itself (which org/domain got the entitlement,
--          and when it lapses).
--
-- The actual entitlement lives in yp.quota (source='promo-launch30', see
-- promo_launch30_grant) — this table is bookkeeping: it is what makes a claim
-- a ONE-TIME event survivable across a quota row being edited or deleted by
-- something else, and what the expiry worker polls to find trials past
-- trial_ends_at (promo_launch30_due / promo_launch30_mark_expired).
CREATE TABLE IF NOT EXISTS `promo_launch30` (
  `id`              int(11) unsigned NOT NULL AUTO_INCREMENT,
  `payer_id`        varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `status`          enum('unclaimed','claimed','expired') NOT NULL DEFAULT 'unclaimed',
  -- Populated only once claimed — the org_provision-created (or reused)
  -- organisation that received the Team entitlement.
  `org_id`          varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `domain_id`       int(11) unsigned DEFAULT NULL,
  `claimed_at`      int(11) unsigned DEFAULT NULL,
  `trial_ends_at`   int(11) unsigned DEFAULT NULL,
  `expired_at`      int(11) unsigned DEFAULT NULL,
  -- "Shown once" per surface, forever — a row can exist here before any claim
  -- (dismissed without claiming) purely to hold these.
  `home_seen_at`    int(11) unsigned DEFAULT NULL,
  `billing_seen_at` int(11) unsigned DEFAULT NULL,
  `ctime`           int(11) unsigned NOT NULL,
  `mtime`           int(11) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `payer_id` (`payer_id`),
  KEY `idx_status_trial_end` (`status`, `trial_ends_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
