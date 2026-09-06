DELIMITER $

-- =========================================================
-- my_organisations
-- =========================================================
-- Every organisation a person belongs to, newest membership last, with the one
-- they are acting in flagged.
--
-- THE PLURAL OF my_organisation, and deliberately a separate routine rather
-- than a rewrite of it. That one answers "the organisation" and is wired into
-- the boot payload (service/lib/env.js sets data.organization from it), where a
-- shape change would ripple through every client that reads Organization. This
-- one answers "the organisations", which is a question nothing asked before.
--
-- Today it returns exactly one row for everybody: yp.privilege still carries a
-- unique key on uid alone, so a person has one membership. That is the point —
-- the client can be written against the real shape now and needs no change on
-- the day a second row becomes possible.
--
-- `is_home` is the membership that owns the person's identity records
-- (drumate.domain_id, their vhost, their entity), as opposed to one they merely
-- joined. `is_current` is the domain they are acting in, which is what
-- drumate.domain_id names. The two are the same value for every account that
-- exists today and will diverge the moment membership stops relocating people.
--
-- DOMAIN 1 IS EXCLUDED, matching my_organisation's own rule minus its
-- metadata.isOrganization exception: the default public domain is where every
-- account lives before it belongs to anything, and listing "Drumee Stage
-- Server" as an organisation you could switch into would offer 231 accounts a
-- tenancy none of them owns.
DROP PROCEDURE IF EXISTS `my_organisations`$
CREATE PROCEDURE `my_organisations`(
  IN _uid VARCHAR(16),
  IN _acting_domain_id INT
)
BEGIN
  SELECT
    o.id,
    o.domain_id,
    o.name,
    o.link,
    o.link                                        AS url,
    o.ident,
    o.owner_id,
    p.privilege,
    -- HOME: the membership that owns this person's identity records
    -- (drumate.domain_id, their vhost, their entity), as opposed to one they
    -- merely joined.
    --
    -- This used to have a second arm -- "or it is your only membership" --
    -- because is_authoritative was defaulted 0 and written by nothing, so the
    -- flag could not be trusted on its own. The backfill in
    -- patches/2026-09-07-privilege-multi-domain.sql has since run and every
    -- one of the 306 rows carries a 1, with domain_grant and domain_join now
    -- maintaining it. The fallback is therefore not merely redundant, it is
    -- wrong: it would report a joined-only account's sole membership as home
    -- when domain_join deliberately left is_authoritative at 0.
    IFNULL(p.is_authoritative, 0)                 AS is_home,
    -- CURRENT: the organisation being acted in, which is NOT derivable from
    -- the tables. It used to be computed as p.domain_id = d.domain_id, joined
    -- on drumate -- but drumate.domain_id IS home, so that expression made
    -- is_current identically equal to is_home and it could never mark an
    -- organisation someone had merely joined. The switcher would have ticked
    -- the wrong row for exactly the accounts the switcher exists to serve.
    --
    -- So the caller passes it, because only the caller knows: it is a property
    -- of the request, not of the data. NULL means "no acting domain resolved"
    -- and falls back to home, which is what every request means today.
    IF(p.domain_id = IFNULL(_acting_domain_id, d.domain_id), 1, 0) AS is_current,
    IF(o.owner_id = _uid, 1, 0)                   AS is_owner
  FROM privilege p
  INNER JOIN organisation o ON o.domain_id = p.domain_id
  INNER JOIN drumate d      ON d.id = p.uid
  WHERE p.uid = _uid
    AND p.domain_id <> 1
  ORDER BY is_current DESC, is_home DESC, o.name ASC;
END$

DELIMITER ;
