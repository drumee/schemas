DELIMITER $

-- =========================================================
-- quota_plan_sync — reconcile yp.quota rows with the ACTIVE plan catalog
--
-- yp.quota holds a COPY of a plan's quota JSON, taken at the moment the
-- entitlement was granted (payment_apply_entitlement, promo_launch30_grant,
-- mkt_coupon_redeem all work that way). When the catalog later changes —
-- the 2026-07 flat-pricing rebuild, the 2026-07-27 workspace caps, the
-- 2026-08-03 Pro tier — rows granted BEFORE the change keep the old numbers
-- until something rewrites them. Nothing does, unless the customer renews.
--
-- Observed on prod 2026-08-07: 20 LAUNCH30 orgs on 50 GB / 0 seats while
-- Team sells 100 GB / 10, and one paying Business org with seat = 1 — which
-- the downgrade over-limit feature would read as 'over seats' and lock.
--
-- The granting code is NOT at fault (it reads the catalog); this is
-- historical residue, so the cure is a backfill, not a code change.
--
-- ── Safety, which is the whole point of this procedure ──────────────────
--
-- Making a row match the catalog can REDUCE what a customer already has.
-- Cutting disk under their stored bytes blocks every upload; cutting seats
-- under their headcount trips the over-limit lock. So each row is graded by
-- DIRECTION and the caller chooses how far to go:
--
--   'audit'  report only, writes nothing (the default, and what to run first)
--   'raise'  apply only rows where nothing becomes less generous
--   'all'    apply everything EXCEPT rows whose stored bytes exceed the new
--            disk (those are reported as 'skip_usage')
--   'force'  apply everything, including rows that would strand a customer
--            over quota — an explicit product decision, never a default
--
-- Never touched: source 'reward' / 'sovereign' (sold outside the catalog,
-- BIGINT-max disk by design) and any plan_code with no ACTIVE catalog row.
--
-- Fields are written with JSON_SET, not by replacing the object, so keys the
-- catalog does not carry survive. desk_disk / hub_disk are updated only when
-- the row already has them — disk_limit reads IFNULL($.desk_disk, $.disk),
-- so absent is correct, and adding them where they were absent would be a
-- change nobody asked for. The workspace caps mirror the catalog exactly:
-- set when it defines them, REMOVED when it does not (Business sells
-- "Multiple", and a stale cap left by an upgraded-from plan would cap it).
--
-- Idempotent: a second run finds nothing to do.
-- =========================================================
DROP PROCEDURE IF EXISTS `quota_plan_sync`$
CREATE PROCEDURE `quota_plan_sync`(
  IN _mode  VARCHAR(16),   -- audit | raise | all | force
  IN _apply TINYINT        -- 0 = report what would change, 1 = write
)
proc: BEGIN
  DECLARE _now INT UNSIGNED;
  -- seat semantics, straight out of hub.js _seatBudget: 0 (or absent) and the
  -- 100000 sentinel both mean "no cap". Normalising them to +inf is what lets
  -- one comparison decide whether a change is generous or not.
  DECLARE _inf BIGINT DEFAULT 9223372036854775807;
  DECLARE _stale INT DEFAULT 0;

  SET _now = UNIX_TIMESTAMP();
  SET _mode = LOWER(TRIM(IFNULL(NULLIF(_mode, ''), 'audit')));
  SET _apply = IFNULL(_apply, 0);

  IF _mode NOT IN ('audit', 'raise', 'all', 'force') THEN
    SELECT 'MODE_INVALID' AS error, _mode AS mode,
           'audit | raise | all | force' AS expected;
    LEAVE proc;
  END IF;
  IF _mode = 'audit' THEN SET _apply = 0; END IF;

  -- ── Precondition: the catalog must not be BEHIND the rows it rewrites ──
  --
  -- Everything below treats the active catalog as ground truth. That is only
  -- safe while the catalog is itself up to date; a catalog that MISSED a
  -- patch would be faithfully copied onto every entitlement, turning this
  -- procedure into the thing that spreads the drift.
  --
  -- The live example: prod's active free/team rows carry no workspace caps
  -- (the 2026-07-27 patch reached the quota rows but not the catalog), while
  -- 123 quota rows carry them correctly. Trusting the catalog there would
  -- REMOVE the caps from all of them — and because dropping a cap is a
  -- loosening, not a tightening, it would slip through even 'raise'.
  --
  -- So: if any quota row carries a cap its own plan's catalog row lacks,
  -- stop and say which patch is missing. Business is exempt by design — it
  -- sells "Multiple" and is meant to be cap-free.
  SELECT COUNT(*) INTO _stale
    FROM `quota` q
   INNER JOIN (
     SELECT plan_code, MAX(JSON_EXISTS(quota, '$.private_hub')) AS has_caps
       FROM `plan` WHERE active = 1 GROUP BY plan_code
   ) c ON c.plan_code = LOWER(COALESCE(JSON_VALUE(q.quota, '$.plan'), q.plan))
   WHERE c.has_caps = 0
     AND JSON_EXISTS(q.quota, '$.private_hub')
     AND LOWER(COALESCE(JSON_VALUE(q.quota, '$.plan'), q.plan))
         NOT IN ('business', 'sovereign', 'enterprise');

  IF _stale > 0 THEN
    SELECT 'CATALOG_STALE' AS error,
           _stale AS rows_that_would_lose_caps,
           'yellow_page/patches/2026-07-27-plan-workspace-caps.sql' AS apply_this_first,
           'the active plan catalog lacks workspace caps that live entitlements already carry' AS detail;
    LEAVE proc;
  END IF;

  DROP TEMPORARY TABLE IF EXISTS `_qps`;
  CREATE TEMPORARY TABLE `_qps` (
    id         INT UNSIGNED NOT NULL PRIMARY KEY,
    domain_id  INT UNSIGNED,
    payer_id   VARCHAR(16) CHARACTER SET ascii,
    plan_code  VARCHAR(80) CHARACTER SET ascii,
    source     VARCHAR(16) CHARACTER SET ascii,
    cur_disk BIGINT UNSIGNED, want_disk BIGINT UNSIGNED,
    cur_seat BIGINT,          want_seat BIGINT,
    cur_hist BIGINT,          want_hist BIGINT,
    cur_org  BIGINT,          want_org  BIGINT,
    cur_ph   BIGINT,          want_ph   BIGINT,
    cur_sh   BIGINT,          want_sh   BIGINT,
    cur_pub  BIGINT,          want_pub  BIGINT,
    cat_caps TINYINT,
    has_dd   TINYINT,
    has_hd   TINYINT,
    used     BIGINT UNSIGNED,
    lowers   TINYINT DEFAULT 0,
    verdict  VARCHAR(16)
  ) ENGINE=MEMORY;

  -- One representative catalog row per plan_code. month and year carry
  -- identical quota (the period sets the price, not the allowance), so MAX
  -- over the group is the value, not an approximation of it.
  INSERT INTO `_qps`
  SELECT
    q.id, q.domain_id, q.payer_id,
    LOWER(COALESCE(JSON_VALUE(q.quota, '$.plan'), q.plan)),
    q.source,
    CAST(JSON_VALUE(q.quota, '$.disk')           AS UNSIGNED), c.disk,
    CAST(JSON_VALUE(q.quota, '$.seat')           AS SIGNED),   c.seat,
    CAST(JSON_VALUE(q.quota, '$.history_length') AS SIGNED),   c.hist,
    CAST(JSON_VALUE(q.quota, '$.organization')   AS SIGNED),   c.org,
    CAST(JSON_VALUE(q.quota, '$.private_hub')    AS SIGNED),   c.ph,
    CAST(JSON_VALUE(q.quota, '$.share_hub')      AS SIGNED),   c.sh,
    CAST(JSON_VALUE(q.quota, '$.public_hub')     AS SIGNED),   c.pub,
    c.has_caps,
    JSON_EXISTS(q.quota, '$.desk_disk'),
    JSON_EXISTS(q.quota, '$.hub_disk'),
    IFNULL(u.cached_usage, 0),
    0, NULL
  FROM `quota` q
  INNER JOIN (
    SELECT plan_code,
           MAX(CAST(JSON_VALUE(quota, '$.disk')           AS UNSIGNED)) AS disk,
           MAX(CAST(JSON_VALUE(quota, '$.seat')           AS SIGNED))   AS seat,
           MAX(CAST(JSON_VALUE(quota, '$.history_length') AS SIGNED))   AS hist,
           MAX(CAST(JSON_VALUE(quota, '$.organization')   AS SIGNED))   AS org,
           MAX(CAST(JSON_VALUE(quota, '$.private_hub')    AS SIGNED))   AS ph,
           MAX(CAST(JSON_VALUE(quota, '$.share_hub')      AS SIGNED))   AS sh,
           MAX(CAST(JSON_VALUE(quota, '$.public_hub')     AS SIGNED))   AS pub,
           MAX(JSON_EXISTS(quota, '$.private_hub'))                     AS has_caps
      FROM `plan`
     WHERE active = 1
     GROUP BY plan_code
  ) c ON c.plan_code = LOWER(COALESCE(JSON_VALUE(q.quota, '$.plan'), q.plan))
  LEFT JOIN `quota_usage` u ON u.domain_id = q.domain_id
  WHERE IFNULL(q.source, '') NOT IN ('reward', 'sovereign');

  -- Drop the rows that already agree with the catalog: nothing to report,
  -- nothing to write. Caps count as agreeing when the catalog defines none
  -- and the row carries none.
  DELETE FROM `_qps`
   WHERE IFNULL(cur_disk, 0) = want_disk
     AND IFNULL(cur_seat, 0) = IFNULL(want_seat, 0)
     AND IFNULL(cur_hist, 0) = IFNULL(want_hist, 0)
     AND IFNULL(cur_org,  0) = IFNULL(want_org,  0)
     AND ((cat_caps = 1
           AND IFNULL(cur_ph, -1)  = IFNULL(want_ph, -1)
           AND IFNULL(cur_sh, -1)  = IFNULL(want_sh, -1)
           AND IFNULL(cur_pub, -1) = IFNULL(want_pub, -1))
       OR (cat_caps <> 1
           AND cur_ph IS NULL AND cur_sh IS NULL AND cur_pub IS NULL));

  -- How many fields would become LESS generous. Absent means unlimited for
  -- the caps and for seat; it means zero for disk and history_length.
  UPDATE `_qps` SET lowers =
      (want_disk < IFNULL(cur_disk, 0))
    + (IF(want_seat IS NULL OR want_seat <= 0 OR want_seat >= 100000, _inf, want_seat)
       < IF(cur_seat  IS NULL OR cur_seat  <= 0 OR cur_seat  >= 100000, _inf, cur_seat))
    + (IFNULL(want_hist, 0) < IFNULL(cur_hist, 0))
    + (cat_caps = 1 AND IFNULL(want_ph,  _inf) < IFNULL(cur_ph,  _inf))
    + (cat_caps = 1 AND IFNULL(want_sh,  _inf) < IFNULL(cur_sh,  _inf))
    + (cat_caps = 1 AND IFNULL(want_pub, _inf) < IFNULL(cur_pub, _inf));

  -- 'audit' previews what 'all' would do — the realistic target — so the
  -- usage guard is visible in the report instead of only at apply time.
  -- What 'raise' would do is readable from the same output: every row with
  -- lowers > 0 is one 'raise' declines to touch.
  UPDATE `_qps` SET verdict =
    CASE
      WHEN lowers = 0                                       THEN 'apply'
      WHEN _mode = 'raise'                                  THEN 'skip_lower'
      WHEN _mode IN ('all', 'audit') AND used > want_disk   THEN 'skip_usage'
      ELSE 'apply'
    END;

  IF _apply = 1 THEN
    UPDATE `quota` q
      INNER JOIN `_qps` t ON t.id = q.id
       SET q.quota =
             -- Caps last, mirroring the catalog: set them when it defines
             -- them, remove them when it does not.
             IF(t.cat_caps = 1,
               JSON_SET(
                 IF(t.has_hd,
                   JSON_SET(
                     IF(t.has_dd,
                       JSON_SET(q.quota,
                         '$.plan', t.plan_code, '$.disk', t.want_disk,
                         '$.seat', t.want_seat, '$.history_length', t.want_hist,
                         '$.organization', t.want_org, '$.desk_disk', t.want_disk),
                       JSON_SET(q.quota,
                         '$.plan', t.plan_code, '$.disk', t.want_disk,
                         '$.seat', t.want_seat, '$.history_length', t.want_hist,
                         '$.organization', t.want_org)),
                     '$.hub_disk', t.want_disk),
                   IF(t.has_dd,
                     JSON_SET(q.quota,
                       '$.plan', t.plan_code, '$.disk', t.want_disk,
                       '$.seat', t.want_seat, '$.history_length', t.want_hist,
                       '$.organization', t.want_org, '$.desk_disk', t.want_disk),
                     JSON_SET(q.quota,
                       '$.plan', t.plan_code, '$.disk', t.want_disk,
                       '$.seat', t.want_seat, '$.history_length', t.want_hist,
                       '$.organization', t.want_org))),
                 '$.private_hub', t.want_ph,
                 '$.share_hub',   t.want_sh,
                 '$.public_hub',  t.want_pub),
               JSON_REMOVE(
                 IF(t.has_hd,
                   JSON_SET(
                     IF(t.has_dd,
                       JSON_SET(q.quota,
                         '$.plan', t.plan_code, '$.disk', t.want_disk,
                         '$.seat', t.want_seat, '$.history_length', t.want_hist,
                         '$.organization', t.want_org, '$.desk_disk', t.want_disk),
                       JSON_SET(q.quota,
                         '$.plan', t.plan_code, '$.disk', t.want_disk,
                         '$.seat', t.want_seat, '$.history_length', t.want_hist,
                         '$.organization', t.want_org)),
                     '$.hub_disk', t.want_disk),
                   IF(t.has_dd,
                     JSON_SET(q.quota,
                       '$.plan', t.plan_code, '$.disk', t.want_disk,
                       '$.seat', t.want_seat, '$.history_length', t.want_hist,
                       '$.organization', t.want_org, '$.desk_disk', t.want_disk),
                     JSON_SET(q.quota,
                       '$.plan', t.plan_code, '$.disk', t.want_disk,
                       '$.seat', t.want_seat, '$.history_length', t.want_hist,
                       '$.organization', t.want_org))),
                 '$.private_hub', '$.share_hub', '$.public_hub')),
           -- Keep the denormalised column in step with $.plan.
           q.plan  = t.plan_code,
           q.mtime = _now
     WHERE t.verdict = 'apply';
  END IF;

  -- Result set 1: what happened (or would).
  SELECT _mode AS mode, _apply AS applied,
         SUM(verdict = 'apply')      AS n_apply,
         SUM(verdict = 'skip_lower') AS n_skip_lower,
         SUM(verdict = 'skip_usage') AS n_skip_usage,
         COUNT(*)                    AS n_drifted
    FROM `_qps`;

  -- Result set 2: the rows themselves, worst first.
  SELECT id, domain_id, payer_id, plan_code, source, verdict, lowers,
         cur_disk, want_disk, cur_seat, want_seat,
         cur_hist, want_hist, cur_org, want_org,
         cur_ph, want_ph, cur_sh, want_sh, cur_pub, want_pub,
         cat_caps, used
    FROM `_qps`
   ORDER BY (verdict <> 'apply') DESC, lowers DESC, plan_code, id;

  DROP TEMPORARY TABLE IF EXISTS `_qps`;
END $

-- Read-only shorthand: the thing to run first, on any environment.
DROP PROCEDURE IF EXISTS `quota_plan_audit`$
CREATE PROCEDURE `quota_plan_audit`()
BEGIN
  CALL quota_plan_sync('audit', 0);
END $

DELIMITER ;
