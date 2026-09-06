DELIMITER $

-- =========================================================
-- domain_join
-- =========================================================
-- JOIN somebody else's organisation: gain a membership in it, keep your own
-- home.
--
-- The counterpart to domain_grant. That one is for the four provisioning paths
-- and means "this domain is now mine and my records live in it"; this one is
-- for invitations and means "I can act here too". The distinction is the whole
-- point of widening yp.privilege's key to (uid, domain_id): before that, the
-- two were indistinguishable, because a second membership could not exist and
-- accepting an invitation therefore MOVED the invitee -- out of their own
-- organisation, taking their drumate row, their vhost and their entity with
-- them.
--
-- HOME IS NOT TOUCHED. No UPDATE of drumate/vhost/entity here, and the new row
-- is written with is_authoritative = 0. Someone who owns an organisation and
-- joins a second keeps the first as home; their address does not change and
-- their personal hubs do not migrate.
--
-- WITH ONE EXCEPTION, and it is not a special case so much as the same rule.
-- Domain 1 is the shared public pool, not an organisation. Somebody whose only
-- membership is there has no home in any meaningful sense, so the organisation
-- they are joining becomes it -- exactly as domain_grant would have done, and
-- exactly what accepting an invitation used to do for the 231 accounts sitting
-- in the pool today. Anyone who already belongs to a real organisation keeps it.
--
-- IDEMPOTENT. Re-inviting an existing member updates their tier and nothing
-- else -- no home change, no second row (the unique key forbids it), and no
-- error for the caller to special-case.
DROP PROCEDURE IF EXISTS `domain_join`$
CREATE PROCEDURE `domain_join`(
  IN _domain_id INT,
  IN _privilege TINYINT(4),
  IN _uid VARCHAR(16),
  IN _show_results BOOLEAN
)
proc: BEGIN
  DECLARE _home INT DEFAULT NULL;

  -- Joining the public pool is not a thing anyone does deliberately, and the
  -- rest of this routine assumes the target is a real organisation.
  IF IFNULL(_domain_id, 0) <= 1 THEN
    SELECT 'INVALID_DOMAIN' AS error;
    LEAVE proc;
  END IF;

  -- The home they have now, if any. NULL for an account with no privilege row
  -- at all; 1 for one that has never left the pool.
  SELECT domain_id INTO _home
    FROM privilege
   WHERE uid = _uid AND is_authoritative = 1
   LIMIT 1;

  INSERT INTO privilege (uid, privilege, domain_id, is_authoritative)
  VALUES (_uid, _privilege, _domain_id, 0)
  ON DUPLICATE KEY UPDATE privilege = _privilege;

  -- No real home yet: this organisation becomes it, and the pool membership
  -- goes with it. Identical in effect to what domain_grant does, and reached
  -- only by people for whom it is the first organisation they have ever been in.
  IF _home IS NULL OR _home = 1 THEN
    UPDATE privilege SET is_authoritative = 1
     WHERE uid = _uid AND domain_id = _domain_id;
    DELETE FROM privilege WHERE uid = _uid AND domain_id = 1;
    UPDATE drumate SET domain_id = _domain_id WHERE id = _uid;
    UPDATE vhost   SET dom_id    = _domain_id WHERE id = _uid;
    UPDATE entity  SET dom_id    = _domain_id WHERE id = _uid;
  END IF;

  IF IFNULL(_show_results, 0) != 0 THEN
    SELECT p.* FROM privilege p WHERE p.uid = _uid AND p.domain_id = _domain_id;
  END IF;
END $

DELIMITER ;
