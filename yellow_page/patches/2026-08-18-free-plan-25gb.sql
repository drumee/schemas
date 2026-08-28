-- =========================================================
-- Free plan storage: 5 GB -> 25 GB (pricing change, Lexis 2026-08-18)
--
-- WHY: product decision. Free is the top of the funnel and 5 GB is not enough
-- room to actually try the product; 25 GB is. Seats are NOT touched — Free
-- stays at the 3 set by 2026-08-14-pricing-free-pro-3-seats.sql.
--
-- ── THE ONE RULE: THIS PATCH CAN ONLY RAISE ─────────────────────────────
--
-- Every write is wrapped in GREATEST(new, current), and the row filter only
-- selects rows already BELOW the new figure. There is no input for which any
-- statement here reduces an allowance. That matters because cutting disk
-- under someone's stored bytes blocks every upload and fires the storage
-- alerts — the failure mode
-- yellow_page/patches/2026-07-24-migrate-free-to-new-allowance.sql had to
-- guard against when it went the other way (20 GB -> 5 GB).
--
-- Going UP has no such hazard: nobody is pushed over quota by being given
-- more, so no usage guard is needed here.
--
-- ── MEASURED BEFORE WRITING (read-only preview of the row filter) ───────
--
-- catalog (`plan`), checked against the FULL live table on both, not just the
-- rows tables/plan.sql seeds — 2 rows each, identical on stage and prod:
--   free/user/free/usd  active 1   5 GB -> 25 GB   (both sub-caps present)
--   free/user/free/eur  active 0  20 GB -> 25 GB   (dormant, swept on purpose)
-- Nothing in the family sits ABOVE 25 GB, so GREATEST never has to hold here;
-- it is there so that stays true if the table changes.
--
-- entitlements (`quota`):
--   PROD  — exactly ONE row: the free fallback (domain 1,
--           payer 'ffffffffffffffff'), 20 GB -> 25 GB. It carries NO
--           $.desk_disk / $.hub_disk keys.
--   STAGE — 8 rows: the same fallback (5 GB) plus six source='stripe' free
--           rows and one 'promo-launch30' free row. All carry both sub-caps.
--
-- ⚠ THESE COUNTS ARE POINT-IN-TIME — RE-MEASURE BEFORE THE PROD APPLY.
-- Stage was first measured at 7 rows and applied at 8: between the two, a
-- subscription lapsed and id 184 moved onto the free plan. That is normal
-- churn, not drift in this patch, and the raise-only rule makes the extra row
-- harmless — but a count you carry over from a previous session is stale by
-- definition. Re-run the row filter as a SELECT immediately before applying,
-- and diff against a backup taken in the same minute.
--
--   Note prod's fallback sits at 20 GB, not the 5 GB the catalog advertises:
--   the 2026-07-24 reduction skipped it because its domain-1 usage (every
--   free account summed) could never fit in 5 GB. So on prod this is a
--   20 -> 25 bump, and it also closes that catalog/reality gap.
--
-- ── SHAPE IS PRESERVED ─────────────────────────────────────────────────
--
-- $.disk is JSON_SET (it always exists). $.desk_disk / $.hub_disk are
-- JSON_REPLACE, which by definition only rewrites keys that are ALREADY
-- there — so prod's fallback row does not sprout sub-caps it never had.
-- disk_limit reads IFNULL($.desk_disk, $.disk), so absent is correct and
-- adding them would be a change nobody asked for (same reasoning as
-- quota_plan_sync's field notes).
--
-- The generated `disk` column follows $.disk automatically; it is never
-- written directly (that would error).
--
-- NOT TOUCHED: source 'reward' / 'sovereign' (sold outside the catalog, hold
-- a BIGINT-max sentinel), every non-free plan, seats, and workspace caps.
--
-- ── THE CATALOG UPDATE DELIBERATELY OMITS `active = 1` ─────────────────
--
-- Same decision as 2026-08-14-pricing-free-pro-3-seats.sql: the whole `free`
-- family is normalised, dormant variants included (the retired EUR row), so a
-- row re-activated later cannot resurrect a stale allowance. Do NOT "fix" this
-- by adding the filter. Nothing live reads a dormant row today — quota_plan_sync
-- and stripe_webhook.js:_planFromItems both filter active = 1 — so the sweep is
-- invisible now and only matters at re-activation, which is the point of it.
-- Unlike that patch, this one still cannot lower anything: GREATEST holds.
--
-- RE-RUNNABLE: absolute values, and a second run matches nothing.
-- =========================================================

-- 1) The catalog. New grants (payment_apply_entitlement, promo_launch30_grant,
--    mkt_coupon_redeem) copy the quota JSON from here, so this is what makes
--    the change stick for everyone who signs up or re-subscribes later.
UPDATE `plan`
   SET `quota` = JSON_SET(`quota`,
         '$.disk',      GREATEST(25000000000, CAST(IFNULL(JSON_VALUE(`quota`, '$.disk'),      0) AS UNSIGNED)),
         '$.desk_disk', GREATEST(25000000000, CAST(IFNULL(JSON_VALUE(`quota`, '$.desk_disk'), 0) AS UNSIGNED)),
         '$.hub_disk',  GREATEST(25000000000, CAST(IFNULL(JSON_VALUE(`quota`, '$.hub_disk'),  0) AS UNSIGNED)))
 WHERE `plan_code`   = 'free'
   AND `entity_type` = 'user';

-- 2) Live entitlements. yp.quota holds a COPY of the plan's quota taken when
--    the entitlement was granted, and nothing else rewrites it — so without
--    this, no existing free account sees the change until it re-subscribes.
--    A literal is used rather than a join to `plan`, so catalog drift cannot
--    steer this statement.
UPDATE `quota`
   SET `quota` = JSON_REPLACE(
                   JSON_SET(`quota`,
                     '$.disk', GREATEST(25000000000,
                                 CAST(IFNULL(JSON_VALUE(`quota`, '$.disk'), 0) AS UNSIGNED))),
                   '$.desk_disk', GREATEST(25000000000,
                                    CAST(IFNULL(JSON_VALUE(`quota`, '$.desk_disk'), 0) AS UNSIGNED)),
                   '$.hub_disk',  GREATEST(25000000000,
                                    CAST(IFNULL(JSON_VALUE(`quota`, '$.hub_disk'),  0) AS UNSIGNED))),
       `mtime` = UNIX_TIMESTAMP()
 WHERE LOWER(COALESCE(JSON_VALUE(`quota`, '$.plan'), `plan`)) = 'free'
   AND IFNULL(`source`, '') NOT IN ('reward', 'sovereign')
   AND CAST(IFNULL(JSON_VALUE(`quota`, '$.disk'), 0) AS UNSIGNED) < 25000000000;

-- 3) Verify. Expect the catalog at 25 GB and no free row left below it.
SELECT 'catalog' AS scope, `currency`, `active`,
       CAST(JSON_VALUE(`quota`, '$.disk') AS UNSIGNED) / 1000000000 AS gb
  FROM `plan`
 WHERE `plan_code` = 'free' AND `entity_type` = 'user';

SELECT 'free rows still below 25 GB (expect 0)' AS scope, COUNT(*) AS n
  FROM `quota`
 WHERE LOWER(COALESCE(JSON_VALUE(`quota`, '$.plan'), `plan`)) = 'free'
   AND IFNULL(`source`, '') NOT IN ('reward', 'sovereign')
   AND CAST(IFNULL(JSON_VALUE(`quota`, '$.disk'), 0) AS UNSIGNED) < 25000000000;
