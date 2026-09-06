-- Let a person belong to more than one organisation.
--
-- yp.privilege carried `UNIQUE KEY (uid)` -- one membership row per person --
-- which is what made an organisation something you are IN rather than
-- something you JOIN. domain_grant reads that constraint literally: it upserts
-- the single row and then relocates the person's identity records
-- (drumate.domain_id, vhost.dom_id, entity.dom_id), so accepting an invitation
-- has always MOVED you out of wherever you were.
--
-- UNIQUE (uid, domain_id), NOT a plain index. Dropping uniqueness altogether
-- would remove the only thing preventing two rows for the same person in the
-- same domain -- nothing writes duplicates today (domain_grant upserts), but
-- the index is what guarantees it, and this patch must not trade one invariant
-- for none. Per-domain uniqueness keeps that guarantee and adds exactly the
-- freedom wanted: many domains, one row each.
--
-- SAFE ON DATA. The index it replaces already guaranteed one row per uid, so
-- every existing row is trivially unique on the wider key and the ALTER cannot
-- fail on a duplicate. 306 rows at time of writing.
--
-- is_authoritative BECOMES LOAD-BEARING. The column has been on the table all
-- along, defaulted 0, written by nothing and read only by domain_privilege
-- (which returns it, and the value is ignored) -- 305 rows at 0 and one stray
-- 1. From here it means HOME: the one domain that owns a person's identity
-- records, as distinct from the domains they merely belong to. Backfilled to 1
-- for every existing row because today's single membership IS everyone's home,
-- so the meaning is unchanged for every account that exists.
--
-- Pairs with yellow_page/procedures/organization/my_organisations.sql, whose
-- is_home falls back to "you have exactly one membership" precisely because
-- this backfill had not run yet. The two want to land together.
--
-- THIS PATCH CHANGES domain_grant, AND THE CHANGE IS NOT OPTIONAL. Read this
-- before assuming the index swap is inert -- an earlier draft of this header
-- claimed it was, and that was wrong.
--
-- domain_grant does:
--     INSERT ... ON DUPLICATE KEY UPDATE privilege=..., domain_id=...
-- whose "duplicate key" WAS uid. Granting domain B to someone already in
-- domain A collided on that key, so the ON DUPLICATE branch rewrote their one
-- row to B: a MOVE. Widen the key to (uid, domain_id) and the collision stops
-- happening, so the same statement INSERTs instead: an ADD.
--
-- That is the behaviour this whole project wants, but it must not arrive by
-- accident, and it leaves a residue if nothing else changes: the caller's old
-- domain-1 row survives, so someone who provisions an organisation stays a
-- member of the shared public pool as well. domain_grant is therefore updated
-- in the same breath to say what it means -- take ownership of this domain,
-- make it home, and leave domain 1 -- rather than relying on an index to imply
-- it. Apply the two together.

ALTER TABLE `privilege`
  DROP INDEX IF EXISTS `uid`,
  ADD UNIQUE KEY IF NOT EXISTS `uid_domain` (`uid`, `domain_id`);

-- Every membership that exists today is its owner's home.
UPDATE `privilege` SET `is_authoritative` = 1 WHERE `is_authoritative` <> 1;
