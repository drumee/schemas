-- File: schemas/yellow_page/tables/quota.sql
-- Purpose: Entitlement rows — one per payer (a user, or an organisation).
--          $.disk drives the VIRTUAL `disk` column and all quota enforcement.
--
-- RECONCILED 2026-07-29 with what is actually deployed
-- (templates/factory/seed/yp.sql, captured from a real installation). The
-- previous declaration here had drifted badly enough to be wrong in ways that
-- mattered:
--
--   * PRIMARY KEY (`domain_id`) — which would allow only ONE row per domain.
--     The deployed key is a surrogate `id` with UNIQUE(domain_id, payer_id),
--     and several rows per domain are routine: org_provision re-keys a payer's
--     personal row onto the new org domain, and every ON DUPLICATE KEY UPDATE
--     in payment_apply_entitlement / reward_grant_storage collides on that
--     composite key, not on domain_id.
--   * No `id`, `ctime`, `mtime`, `source` or `period_end` — payment_apply_
--     entitlement has been inserting ctime/mtime for months, and `source` /
--     `period_end` arrived in 2026-06-22-quota-entitlement-cols.sql.
--
-- NON-DESTRUCTIVE, deliberately. This file used to open with
-- `DROP TABLE IF EXISTS quota`, so applying it to a live database wiped every
-- paid entitlement on the server and cascaded quota_usage away with it. Same
-- rule as yp.plan: CREATE IF NOT EXISTS plus an INSERT IGNORE seed, so a
-- manifest re-run is a no-op. Column changes go in patches/.
CREATE TABLE IF NOT EXISTS `quota` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `domain_id` int(11) unsigned NOT NULL,
  `payer_id` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `plan` varchar(80) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT 'free',
  `seat` int(10) unsigned GENERATED ALWAYS AS (json_value(`quota`,'$.seat')) VIRTUAL,
  `history_length` int(10) unsigned GENERATED ALWAYS AS (json_value(`quota`,'$.history_length')) VIRTUAL,
  `disk` bigint(20) unsigned GENERATED ALWAYS AS (json_value(`quota`,'$.disk')) VIRTUAL,
  `organization` int(10) unsigned GENERATED ALWAYS AS (json_value(`quota`,'$.organization')) VIRTUAL,
  `quota` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`quota`)),
  `ctime` bigint(20) unsigned DEFAULT NULL,
  `mtime` bigint(20) unsigned DEFAULT NULL,
  -- Where the entitlement came from: 'free' | 'stripe' | 'reward'.
  `source` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT 'free',
  -- When it lapses. Enforced at READ time for source='reward' only (see
  -- get_quota / disk_limit / disk_free / my_disk_limit); informational for
  -- Stripe rows, which are removed by payment_clear_entitlement on cancel.
  -- DEFAULT NULL, so every guard has to read NULL as "no expiry" alongside 0.
  `period_end` int(11) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `domain_id` (`domain_id`,`payer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- The free fallback row, resolved by name ('ffffffffffffffff') as the last tier
-- of every entitlement cascade. 25 GB matches the free plan in yp.plan; the
-- 20 GB this file used to seed was the pre-2026-07 allowance, and existing rows
-- still holding it are migrated by
-- yellow_page/patches/2026-07-24-migrate-free-to-new-allowance.sql, then raised
-- to 25 GB by yellow_page/patches/2026-08-18-free-plan-25gb.sql.
INSERT IGNORE INTO `quota` (domain_id, payer_id, plan, quota, source, ctime, mtime)
  VALUES (1, 'ffffffffffffffff', 'free',
    JSON_OBJECT('plan','free', 'seat', 0, 'disk', 25000000000,
                'desk_disk', 25000000000, 'hub_disk', 25000000000, 'organization', 0),
    'free', UNIX_TIMESTAMP(), UNIX_TIMESTAMP());
