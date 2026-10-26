DELIMITER $

-- =========================================================
-- org_join_context
--
-- Everything the server needs to decide whether somebody who has just been
-- given access to a workspace should also become a MEMBER of the organisation
-- that owns it (server-team service/lib/org-membership.js), in one round trip.
--
-- Two notions of membership exist and were never connected: workspace
-- membership (a '*' permission row in the hub database) and organisation
-- membership (a yp.privilege row on the org domain + drumate.domain_id). Plan,
-- storage and seats all read the second, so a person invited into a paid
-- team's workspace stayed on their own Free plan and never counted as a seat.
--
-- One row, always (NULLs where the hub or the account does not exist):
--   hub_type / hub_area / hub_dom / hub_status / hub_owner_id  -- the workspace
--   acc_domain_id / acc_username / acc_category / acc_status    -- the account
--   acc_org_join   -- the '$.org_join' marker written by org_member_join
--   org_id / org_name / org_owner_id  -- organisation owning hub_dom
--   seat           -- the org plan's seat count (get_quota of the org owner)
--   members        -- organisation members, same filter as member_list_stats
--   own_plan       -- 1 when the account carries its own entitlement row
--   username_taken -- 1 when the username already exists on the org domain
--   prev_privilege -- the account's current privilege tier (restored on leave)
-- =========================================================
DROP PROCEDURE IF EXISTS `org_join_context`$
CREATE PROCEDURE `org_join_context`(
  IN _uid    VARCHAR(16) CHARACTER SET ascii,
  IN _hub_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  DECLARE _hub_type     VARCHAR(32);
  DECLARE _hub_area     VARCHAR(32);
  DECLARE _hub_dom      INT UNSIGNED;
  DECLARE _hub_status   VARCHAR(32);
  DECLARE _hub_owner    VARCHAR(16) CHARACTER SET ascii;
  DECLARE _acc_dom      INT UNSIGNED;
  DECLARE _acc_username VARCHAR(255);
  DECLARE _acc_category VARCHAR(64);
  DECLARE _acc_status   VARCHAR(32);
  DECLARE _acc_org_join LONGTEXT;
  DECLARE _org_id       VARCHAR(16) CHARACTER SET ascii;
  DECLARE _org_name     VARCHAR(512);
  DECLARE _org_owner    VARCHAR(16) CHARACTER SET ascii;
  DECLARE _seat         INT;
  DECLARE _members      INT DEFAULT 0;
  DECLARE _own_plan     INT DEFAULT 0;
  DECLARE _taken        INT DEFAULT 0;
  DECLARE _prev_priv    INT DEFAULT 1;

  SELECT e.`type`, e.area, e.dom_id, e.status, h.owner_id
    FROM entity e
    LEFT JOIN hub h ON h.id = e.id
   WHERE e.id = _hub_id
   LIMIT 1
    INTO _hub_type, _hub_area, _hub_dom, _hub_status, _hub_owner;

  SELECT d.domain_id, d.username,
         JSON_VALUE(d.profile, '$.category'),
         e.status,
         JSON_EXTRACT(d.profile, '$.org_join')
    FROM drumate d
    LEFT JOIN entity e ON e.id = d.id
   WHERE d.id = _uid
   LIMIT 1
    INTO _acc_dom, _acc_username, _acc_category, _acc_status, _acc_org_join;

  IF _hub_dom IS NOT NULL AND _hub_dom > 1 THEN
    SELECT o.id, o.name, o.owner_id
      FROM organisation o
     WHERE o.domain_id = _hub_dom
     LIMIT 1
      INTO _org_id, _org_name, _org_owner;
  END IF;

  IF _org_id IS NOT NULL THEN
    SELECT CAST(JSON_VALUE(get_quota(_org_owner), '$.seat') AS INTEGER) INTO _seat;

    -- Same headcount member_list_stats reports as total_members.
    SELECT COUNT(DISTINCT p.uid)
      FROM privilege p
      INNER JOIN drumate d ON p.uid = d.id
      INNER JOIN entity e ON d.id = e.id
     WHERE p.domain_id = _hub_dom
       AND COALESCE(JSON_VALUE(d.profile, '$.category'), '') <> 'system'
       AND e.status NOT IN ('archived', 'frozen', 'deleted')
      INTO _members;

    IF _acc_username IS NOT NULL THEN
      SELECT COUNT(*) FROM drumate
       WHERE username = _acc_username AND domain_id = _hub_dom AND id <> _uid
        INTO _taken;
    END IF;
  END IF;

  -- A personal entitlement of their own (paid, partner grant, reward,
  -- unlimited): the tenant-first cascade would hide it behind the org plan.
  SELECT COUNT(*) FROM quota q
   WHERE q.payer_id = _uid AND q.domain_id = 1
     AND (IFNULL(q.plan, 'free') <> 'free'
          OR IFNULL(q.source, '') = 'reward'
          OR JSON_VALUE(q.quota, '$.unlimited') IN ('true', '1'))
    INTO _own_plan;

  SELECT IFNULL(privilege, 1) FROM privilege WHERE uid = _uid LIMIT 1 INTO _prev_priv;

  SELECT
    _hub_type     AS hub_type,
    _hub_area     AS hub_area,
    _hub_dom      AS hub_dom,
    _hub_status   AS hub_status,
    _hub_owner    AS hub_owner_id,
    _acc_dom      AS acc_domain_id,
    _acc_username AS acc_username,
    _acc_category AS acc_category,
    _acc_status   AS acc_status,
    _acc_org_join AS acc_org_join,
    _org_id       AS org_id,
    _org_name     AS org_name,
    _org_owner    AS org_owner_id,
    _seat         AS seat,
    _members      AS members,
    _own_plan     AS own_plan,
    _taken        AS username_taken,
    _prev_priv    AS prev_privilege;
END $

DELIMITER ;
