DELIMITER $

-- =========================================================
-- domain_grant
-- =========================================================
-- Take OWNERSHIP of a domain: hold a membership in it, make it home, and leave
-- the shared public pool.
--
-- Every caller is a provisioning path -- org_provision, drumate.js's org
-- bootstrap, organization.add, role.js -- and each one means "this person now
-- owns this new domain". None of them is an invitation. Joining somebody
-- else's organisation is domain_join, which grants membership and leaves home
-- alone.
--
-- IT USED TO MOVE PEOPLE BY ACCIDENT OF AN INDEX. The upsert below collided on
-- yp.privilege's old `UNIQUE (uid)`, so its ON DUPLICATE branch rewrote the
-- caller's single row to the new domain. Once that key widened to
-- (uid, domain_id) the collision stopped happening and the same statement began
-- INSERTing -- additive, which is what the product wants, but arrived at
-- silently and leaving the old domain-1 row behind. What follows says the thing
-- out loud instead of leaning on an index to mean it.
--
-- DOMAIN 1 IS NOT AN ORGANISATION. It is where every account lives before it
-- belongs to one, so taking ownership of a real domain means leaving it. That
-- was the old behaviour (the move consumed the domain-1 row) and it stays the
-- behaviour; without this, an account provisioning an organisation would keep a
-- membership in the public pool alongside its own.
--
-- EXACTLY ONE HOME. is_authoritative names the domain that owns the person's
-- identity records -- the same records the three UPDATEs below move. Setting it
-- here and clearing it everywhere else keeps that a fact rather than a hope.
DROP PROCEDURE IF EXISTS `domain_grant`$
CREATE PROCEDURE `domain_grant`(
  IN _domain_id INT,
  IN _privilege TINYINT(4),
  IN _uid VARCHAR(16),
  IN _show_results BOOLEAN
)
BEGIN

  -- Membership in the target domain. `domain_id` is no longer touched by the
  -- ON DUPLICATE branch: it is part of the key now, so a row that matches is
  -- already in the right domain and only its tier can need updating.
  INSERT INTO privilege (uid, privilege, domain_id, is_authoritative)
  VALUES (_uid, _privilege, _domain_id, 1)
  ON DUPLICATE KEY UPDATE privilege = _privilege, is_authoritative = 1;

  -- Leaving the public pool. Guarded so granting domain 1 itself -- which the
  -- setup path does -- cannot remove the row it has just written.
  IF _domain_id <> 1 THEN
    DELETE FROM privilege WHERE uid = _uid AND domain_id = 1;
  END IF;

  -- One home, and it is this one.
  UPDATE privilege SET is_authoritative = 0
   WHERE uid = _uid AND domain_id <> _domain_id;

  -- The identity records themselves follow home.
  UPDATE drumate SET domain_id = _domain_id WHERE id = _uid;
  UPDATE vhost   SET dom_id    = _domain_id WHERE id = _uid;
  UPDATE entity  SET dom_id    = _domain_id WHERE id = _uid;

  IF IFNULL(_show_results, 0) != 0 THEN
    SELECT p.* FROM privilege p WHERE p.uid = _uid AND domain_id = _domain_id;
  END IF;
END $

DELIMITER ;
