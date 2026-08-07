DELIMITER $

-- =========================================================
-- quota_plan_sync — raise entitlement rows that fell BEHIND the plan catalog
--
-- yp.quota holds a COPY of a plan's quota JSON, taken at the moment the
-- entitlement was granted (payment_apply_entitlement, promo_launch30_grant,
-- mkt_coupon_redeem all work that way). When the catalog later changes — the
-- 2026-07 flat-pricing rebuild, the 2026-07-27 workspace caps, the
-- 2026-08-03 Pro tier — rows granted BEFORE the change keep the old numbers
-- until the customer renews. Nothing else rewrites them.
--
-- Measured on prod 2026-08-07: 20 LAUNCH30 orgs on 50 GB while Team sells
-- 100 GB, and one paying Business org whose seat cap reads 1 instead of
-- unlimited. Stage carried a paying Team org on 5 GB. The granting code is
-- NOT at fault (it reads the catalog); this is residue from patch-application
-- timing, so the cure is a backfill.
--
-- ── THE ONE RULE ────────────────────────────────────────────────────────
--
-- A field is raised only when the row's number is BELOW the catalog's.
-- A number that is ABOVE the catalog is left exactly as it is.
--
-- So a Pro row holding the old 5 GB becomes 50 GB, and a seat cap of 1 on
-- Business becomes unlimited — but the Free row sitting on a legacy 20 GB
-- keeps its 20 GB, and the Team row still carrying the pre-rebuild
-- 50 GB × 5 seats = 250 GB keeps that too. Reducing an allowance is a
-- product decision about a specific customer, not a data repair, and it is
-- the one thing that can hurt: cutting disk under someone's stored bytes
-- blocks every upload, and cutting seats under their headcount stops them
-- inviting. This procedure cannot do either.
--
-- The rule is applied PER FIELD, not per row: a row whose disk is short and
-- whose caps are generous gets its disk raised and its caps left alone.
--
-- Never touched at all: source 'reward' / 'sovereign' (sold outside the
-- catalog, BIGINT-max disk by design) and any plan_code with no ACTIVE
-- catalog row.
--
-- ── Field notes ─────────────────────────────────────────────────────────
--
-- seat        0 is not "unlimited by choice", it is the pre-rebuild default.
--             hub.js _seatBudget reads seat <= 0 as no budget at all, so
--             those orgs invite without limit today. Raising 0 to the plan's
--             10 is therefore a tightening in effect, and the only place
--             this procedure can make something smaller — so it is guarded:
--             a seat cap is never written below the org's current occupancy
--             (members + pending invites), which would strand it over its
--             own limit. Verified on prod: every affected org holds 1 member.
-- desk_disk /
-- hub_disk    raised only where the row ALREADY carries them. disk_limit
--             reads IFNULL($.desk_disk, $.disk), so absent is correct and
--             adding them would be a change nobody asked for.
-- caps        a cap is a limit, so a bigger number is more generous and an
--             ABSENT key means unlimited. A row more restrictive than the
--             catalog is raised; a row more generous is left. Where the
--             catalog defines no caps at all — Business, which sells
--             "Multiple" — a stale cap left behind by the plan it was
--             upgraded from is removed.
--
-- Written with JSON_MERGE_PATCH of a patch document holding ONLY the fields
-- that change, so every other key in the row survives untouched.
--
-- Idempotent: a second run finds nothing to do.
--
--   CALL quota_plan_audit();      -- read-only report
--   CALL quota_plan_sync(1);      -- apply
-- =========================================================
DROP PROCEDURE IF EXISTS `quota_plan_sync`$
CREATE PROCEDURE `quota_plan_sync`(
  IN _apply TINYINT   -- 0 = report what would change, 1 = write
)
proc: BEGIN
  DECLARE _now   INT UNSIGNED;
  DECLARE _stale INT DEFAULT 0;

  SET _now = UNIX_TIMESTAMP();
  SET _apply = IF(IFNULL(_apply, 0) = 1, 1, 0);

  -- ── Precondition: the catalog must not be BEHIND the rows it rewrites ──
  --
  -- Everything below treats the active catalog as ground truth, which is
  -- only safe while the catalog is itself up to date. A catalog that missed
  -- a patch would be faithfully copied onto every entitlement, making this
  -- procedure the thing that spreads the drift.
  --
  -- The live case: prod's active free/team rows carry no workspace caps (the
  -- 2026-07-27 patch reached the quota rows but not the catalog) while 123
  -- quota rows carry them correctly. Trusting the catalog there would REMOVE
  -- the caps from all of them — and since dropping a cap is a loosening, the
  -- raise-only rule above would not stop it.
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
    occupied BIGINT DEFAULT 0,   -- members + pending invites, for the seat guard
    seat_held TINYINT DEFAULT 0, -- 1 = seat raise withheld to protect occupancy
    patch    VARCHAR(512)
  ) ENGINE=MEMORY;

  -- One representative catalog row per plan_code. month and year carry
  -- identical quota (the period sets the price, not the allowance), so MAX
  -- over the group is the value, not an approximation of it.
  INSERT INTO `_qps` (id, domain_id, payer_id, plan_code, source,
                      cur_disk, want_disk, cur_seat, want_seat,
                      cur_hist, want_hist, cur_org, want_org,
                      cur_ph, want_ph, cur_sh, want_sh, cur_pub, want_pub,
                      cat_caps, has_dd, has_hd)
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
    JSON_EXISTS(q.quota, '$.hub_disk')
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
  WHERE IFNULL(q.source, '') NOT IN ('reward', 'sovereign');

  -- Current occupancy, for the seat guard. privilege rows on the domain are
  -- the members; pending_invitation rows on its active hubs are the invites
  -- already spent — the same two sources member_list_stats adds up.
  UPDATE `_qps` t
     SET occupied = (
           SELECT COUNT(DISTINCT p.uid) FROM `privilege` p WHERE p.domain_id = t.domain_id
         ) + (
           SELECT COUNT(*) FROM `pending_invitation` pi
            INNER JOIN `entity` he ON he.id = pi.hub_id
            WHERE he.dom_id = t.domain_id
              AND he.status = 'active'
              AND (pi.expiry_time = 0 OR pi.expiry_time > _now)
         )
   WHERE t.domain_id > 1;

  -- A seat raise that would land BELOW what the org already holds is
  -- withheld: it would leave them over their own brand-new limit.
  UPDATE `_qps`
     SET seat_held = 1
   WHERE want_seat > IFNULL(cur_seat, 0)
     AND want_seat < occupied;

  -- The patch document: only the fields that are genuinely behind. CONCAT_WS
  -- drops the NULL members, so a field that needs nothing contributes
  -- nothing. A JSON null removes the key (RFC 7396) — that is how a stale
  -- cap comes off a Business row.
  UPDATE `_qps` SET patch = CONCAT('{', CONCAT_WS(',',
      IF(want_disk > IFNULL(cur_disk, 0), CONCAT('"disk":', want_disk), NULL),
      IF(has_dd = 1 AND want_disk > IFNULL(cur_disk, 0),
         CONCAT('"desk_disk":', want_disk), NULL),
      IF(has_hd = 1 AND want_disk > IFNULL(cur_disk, 0),
         CONCAT('"hub_disk":', want_disk), NULL),
      IF(want_seat > IFNULL(cur_seat, 0) AND seat_held = 0,
         CONCAT('"seat":', want_seat), NULL),
      IF(want_hist > IFNULL(cur_hist, 0), CONCAT('"history_length":', want_hist), NULL),
      IF(want_org  > IFNULL(cur_org,  0), CONCAT('"organization":',  want_org),  NULL),
      -- Caps, only where the catalog defines them and the row is stricter.
      IF(cat_caps = 1 AND cur_ph  IS NOT NULL AND want_ph  > cur_ph,
         CONCAT('"private_hub":', want_ph), NULL),
      IF(cat_caps = 1 AND cur_sh  IS NOT NULL AND want_sh  > cur_sh,
         CONCAT('"share_hub":', want_sh), NULL),
      IF(cat_caps = 1 AND cur_pub IS NOT NULL AND want_pub > cur_pub,
         CONCAT('"public_hub":', want_pub), NULL),
      -- Catalog defines none (Business sells "Multiple") but the row carries
      -- one: strip it, or the plan stays capped by the tier it grew out of.
      IF(cat_caps <> 1 AND cur_ph  IS NOT NULL, '"private_hub":null', NULL),
      IF(cat_caps <> 1 AND cur_sh  IS NOT NULL, '"share_hub":null',   NULL),
      IF(cat_caps <> 1 AND cur_pub IS NOT NULL, '"public_hub":null',  NULL)
    ), '}');

  -- Rows with an empty patch have nothing behind the catalog. Keep the ones
  -- whose seat raise was withheld so the report still names them.
  DELETE FROM `_qps` WHERE patch = '{}' AND seat_held = 0;

  IF _apply = 1 THEN
    UPDATE `quota` q
      INNER JOIN `_qps` t ON t.id = q.id
       SET q.quota = JSON_MERGE_PATCH(q.quota, t.patch),
           q.mtime = _now
     WHERE t.patch <> '{}';
  END IF;

  -- Result set 1: the summary.
  SELECT _apply AS applied,
         SUM(patch <> '{}')  AS n_raised,
         SUM(seat_held = 1)  AS n_seat_withheld,
         COUNT(*)            AS n_behind
    FROM `_qps`;

  -- Result set 2: the rows, and exactly what changes on each.
  SELECT id, domain_id, payer_id, plan_code, source, patch, seat_held, occupied,
         cur_disk, want_disk, cur_seat, want_seat,
         cur_hist, want_hist, cur_org, want_org,
         cur_ph, want_ph, cur_sh, want_sh, cur_pub, want_pub, cat_caps
    FROM `_qps`
   ORDER BY seat_held DESC, plan_code, id;

  DROP TEMPORARY TABLE IF EXISTS `_qps`;
END $

-- Read-only shorthand: the thing to run first, on any environment.
DROP PROCEDURE IF EXISTS `quota_plan_audit`$
CREATE PROCEDURE `quota_plan_audit`()
BEGIN
  CALL quota_plan_sync(0);
END $

DELIMITER ;
