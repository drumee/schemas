
DELIMITER $
DROP PROCEDURE IF EXISTS `disk_limit`$
-- =========================================================
-- disk_limit — how much room is left for _entity_id.
--
-- An ORGANISATION shares ONE allowance. Team sells 100 GB for the team, not
-- 100 GB each, and the entitlement lives on a single org-keyed yp.quota row
-- that every member reads through the tenant-first cascade below.
--
-- Usage has to be measured on the same footing, and it was not. This
-- procedure declared `_org_id` and never assigned it, so the two org-wide
-- branches it carried could never run and every call fell through to the
-- per-OWNER ones — one member's bytes weighed against the whole team's
-- allowance. Ten members on Team therefore had 100 GB each: a terabyte sold
-- as a hundred gigabytes.
--
-- Those org branches would not have helped either. They summed usage through
-- `map_role`, which is the CUSTOM-ROLE assignment table (written by
-- adminpannel/role_map) and holds no rows at all until somebody assigns a
-- custom role — 0 on prod, 1 on stage. Switching them on would have returned
-- zero usage for every org member and handed each of them the full quota:
-- the same bug, larger. Org membership lives in `privilege`, keyed by
-- domain_id, and that is what is joined now.
--
-- Domain 1 is the shared free-users domain — 2991 accounts on prod — so the
-- widening is gated on _domain_id > 1. There, each payer stands alone.
--
-- The trigger-maintained yp.quota_usage cache was the other candidate and was
-- rejected: it disagrees with the live disk_usage rows by 127x on at least
-- one prod domain (1.4 GB cached against 182 GB of real hub data), so reading
-- it here would have replaced a wrong answer with an unreliable one.
--
-- Measured before changing anything: on prod the new figure is IDENTICAL to
-- the old one for every org domain, so nothing moves today. On stage, where
-- orgs do have several members, it correctly starts counting them — domain 3
-- (5 members) goes from 0 to 2.9 GB, domain 2 from 335 MB to 1.6 GB.
--
-- Workspace COUNTS (_cnt_private_hub / _cnt_share_hub) stay per-owner: a
-- workspace cap is about what one person may create, and changing that is a
-- separate question from the storage allowance.
-- =========================================================
CREATE PROCEDURE `disk_limit`(
  _entity_id  VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  DECLARE _uid VARCHAR(16)  CHARACTER SET ascii;
  DECLARE _hub_id VARCHAR(16)  CHARACTER SET ascii;
  DECLARE _owner_id VARCHAR(16)  CHARACTER SET ascii;
  DECLARE _drumate_id VARCHAR(16)  CHARACTER SET ascii;
  DECLARE _quota json ;
  DECLARE _domain_id INT(11) UNSIGNED;
  DECLARE _scope VARCHAR(8) DEFAULT 'owner';

  DECLARE _u_desk_disk  double  default 0.0 ;
  DECLARE _u_hub_disk  double  default 0.0 ;

  DECLARE _q_desk_disk  double  default 0.0 ;
  DECLARE _q_hub_disk  double  default 0.0 ;
  DECLARE _q_disk  double  default 0.0 ;
  DECLARE _watermark VARCHAR(16)  CHARACTER SET ascii default "0";

  DECLARE _l_disk  double  default 0.0 ;

  DECLARE _q_share_hub  double  default 0.0 ;
  DECLARE _q_private_hub  double  default 0.0 ;
  DECLARE _cnt_share_hub int;
  DECLARE _cnt_private_hub int;

  SELECT id, owner_id  FROM yp.hub WHERE id = _entity_id  INTO _hub_id, _owner_id;
  SELECT id FROM yp.drumate WHERE id = _entity_id  AND  _owner_id IS NULL  INTO _owner_id;

  -- Entitlement source = yp.quota (canonical). Cascade mirrors get_quota with a
  -- legacy drumate.profile.quota fallback (tier 3) so existing un-migrated users
  -- keep their quota; only paid/explicit yp.quota rows override it.
  SELECT domain_id FROM yp.drumate WHERE id = _owner_id INTO _domain_id;
  -- Tenant-first entitlement: when the user lives in an org domain, the
  -- ORGANISATION's quota row (payer_id = organisation.id) outranks any
  -- personal payer row — a pro→team upgrader owns both for a while and
  -- must see/enforce the TEAM plan, not their stale personal one. The
  -- org row is matched via organisation (deterministic: a domain can now
  -- hold several rows under UNIQUE(domain_id, payer_id)).
  IF _domain_id > 1 THEN
    SELECT q.quota FROM yp.quota q
      INNER JOIN yp.organisation o ON o.domain_id = q.domain_id AND o.id = q.payer_id
     WHERE q.domain_id = _domain_id LIMIT 1 INTO _quota;
  END IF;
  -- An EXPIRED reward is skipped, dropping through to the tiers below. The
  -- claim-reward campaign grants 5 years of unlimited storage as a
  -- source='reward' row and period_end is enforced at READ time, so the term
  -- ends on its own without a sweeper that has to still be installed in 2031.
  --
  -- Scoped to source='reward': Stripe rows carry period_end informationally
  -- (cancellation DELETEs the row), so expiring them here would revoke live
  -- subscriptions over a late webhook. NULL reads as "no expiry" alongside 0 --
  -- period_end is DEFAULT NULL in the deployed schema.
  IF _quota IS NULL THEN
    SELECT quota FROM yp.quota
     WHERE payer_id = _owner_id
       AND (IFNULL(source, 'free') <> 'reward'
            OR IFNULL(period_end, 0) = 0
            OR period_end > UNIX_TIMESTAMP())
     LIMIT 1 INTO _quota;
  END IF;
  IF _quota IS NULL THEN
    SELECT quota FROM yp.drumate WHERE id = _owner_id INTO _quota;                 -- tier 3: legacy profile.quota
  END IF;
  IF _quota IS NULL THEN
    SELECT quota FROM yp.quota WHERE payer_id = 'ffffffffffffffff' AND domain_id = 1 LIMIT 1 INTO _quota; -- tier 4: free
  END IF;

  IF _quota IS NULL THEN
    SELECT conf_value FROM sys_conf WHERE conf_key='default_quota'
      INTO _watermark;
  END IF;
  SELECT JSON_VALUE(_quota, "$.disk") INTO _q_disk;
  SELECT JSON_VALUE(_quota, "$.desk_disk") INTO _q_desk_disk;
  SELECT JSON_VALUE(_quota, "$.hub_disk") INTO _q_hub_disk;
  -- Absent means "no separate sub-cap": the whole allowance may go either way.
  SELECT IFNULL(_q_desk_disk,_q_disk) INTO _q_desk_disk;
  SELECT IFNULL(_q_hub_disk,_q_disk) INTO _q_hub_disk;

  SELECT JSON_VALUE(_quota, "$.share_hub") INTO _q_share_hub;
  SELECT JSON_VALUE(_quota, "$.private_hub") INTO _q_private_hub;

  --  hub_cnt — per-owner on purpose, see the header.
  SELECT
    SUM(CASE WHEN e.area = 'private' then 1 else 0 END ),
    SUM(CASE WHEN e.area = 'share' then 1 else 0 END)
    FROM
      yp.hub h
    INNER JOIN yp.entity e on e.id =  h.id
    WHERE
    h.owner_id=_owner_id AND
    e.area  IN ('private','share')
    INTO  _cnt_private_hub, _cnt_share_hub ;

  -- USAGE. One allowance per organisation, so an org domain is measured
  -- across every member; a personal account is measured alone. `IN (…)`
  -- rather than a join so a member holding more than one privilege row
  -- cannot count their bytes twice.
  IF _domain_id > 1 THEN
    SET _scope = 'domain';

    SELECT SUM(du.size)
      FROM yp.disk_usage du
      INNER JOIN yp.hub h ON du.hub_id = h.id
     WHERE h.owner_id IN (SELECT p.uid FROM yp.privilege p WHERE p.domain_id = _domain_id)
      INTO _u_hub_disk;

    SELECT SUM(du.size)
      FROM yp.disk_usage du
      INNER JOIN yp.drumate d ON du.hub_id = d.id
     WHERE d.id IN (SELECT p.uid FROM yp.privilege p WHERE p.domain_id = _domain_id)
      INTO _u_desk_disk;
  ELSE
    SET _scope = 'owner';

    SELECT SUM(du.size)
      FROM yp.disk_usage du
      INNER JOIN yp.hub h ON du.hub_id = h.id
     WHERE h.owner_id = _owner_id
      INTO _u_hub_disk;

    SELECT SUM(du.size)
      FROM yp.disk_usage du
      INNER JOIN yp.drumate d ON du.hub_id = d.id
     WHERE d.id = _owner_id
      INTO _u_desk_disk;
  END IF;

  SELECT IFNULL(_u_hub_disk, 0)  INTO _u_hub_disk;
  SELECT IFNULL(_u_desk_disk, 0) INTO _u_desk_disk;

  -- The total term is the same either way; the context only decides which
  -- sub-cap also applies — the desk one when asked about a desk, the hub one
  -- when asked about a hub.
  IF _hub_id IS NULL THEN
    SELECT LEAST( _q_disk - _u_desk_disk - _u_hub_disk, _q_desk_disk - _u_desk_disk ) INTO _l_disk;
  ELSE
    SELECT LEAST( _q_disk - _u_desk_disk - _u_hub_disk, _q_hub_disk  - _u_hub_disk  ) INTO _l_disk;
  END IF;

  SELECT _hub_id  hub_id,
  _owner_id owner_id,
  _quota quota,
  NULL org_id,
  _entity_id entity_id,
  _u_desk_disk used_desk_disk,
  _u_hub_disk used_hub_disk,
  _q_disk quota_disk,
  _q_desk_disk quota_desk_disk,
  _q_hub_disk quota_hub_disk,
  _l_disk available_disk,
  -- Whether the usage above spans the organisation or just this payer.
  _scope usage_scope,
  -- Unlimited storage (claim-reward entitlement). The disk figures above stay
  -- arithmetically correct -- $.disk carries the BIGINT sentinel, so
  -- available_disk is a vast positive rather than a negative -- but they are
  -- not a number to SHOW anyone. Callers render "Unlimited" off this flag and
  -- ignore the rest.
  IF(JSON_VALUE(_quota, '$.unlimited') IN ('true', '1'), 1, 0) unlimited,
  _q_share_hub quota_share_hub,
  _q_private_hub quota_private_hub,
  _cnt_share_hub used_share_hub,
  _cnt_private_hub used_private_hub,
  _q_share_hub - _cnt_share_hub  avaialable_share_hub,
  _watermark watermark,
  _q_private_hub - _cnt_private_hub available_private_hub ;

END$

DELIMITER ;
