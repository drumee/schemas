DELIMITER $

-- =========================================================
-- domain_leave
-- =========================================================
-- Give up a membership. The counterpart to domain_join, and the half that was
-- missing: until now the only DELETEs against yp.privilege were domain_grant
-- and domain_join dropping the domain-1 pool row on the way IN, and
-- drumate_delete / drumate_vanish / entity_delete removing the whole account.
-- Membership was one-way, which was invisible while a second one could not
-- exist and becomes a trap the moment invitations start creating them: no way
-- to leave, and no way to remove somebody without deleting them.
--
-- LEAVING AN ORGANISATION YOU MERELY JOINED IS A ROW DELETE. Nothing else
-- points at it -- that is exactly what domain_join promised when it wrote the
-- row with is_authoritative = 0 and left the identity records alone.
--
-- LEAVING YOUR HOME IS NOT, because domain_grant moved three records into it:
-- drumate.domain_id, vhost.dom_id and entity.dom_id. Delete the row and those
-- three still name a domain the person no longer belongs to -- their address
-- and their personal hubs sitting inside an organisation that cannot see them,
-- and the "exactly one is_authoritative row per uid" invariant broken, which
-- my_organisation now depends on. So home has to go somewhere first, and this
-- procedure is the mirror image of domain_grant rather than a DELETE.
--
--   1. THE OWNER MAY NOT LEAVE. An organisation without an owner has nobody
--      who can be billed for it or administer it, and organisation.owner_id is
--      referenced all over (payment, seat budgets, quota). Transfer it or
--      delete the account. Note the owner is NOT identifiable by tier: on the
--      live data owners hold 63, one holds 15, and one has no privilege row at
--      all -- organisation.owner_id is the only sound test.
--   2. OTHERWISE PROMOTE ANOTHER MEMBERSHIP. Highest privilege wins, then the
--      lowest domain_id so the choice is deterministic rather than whatever
--      order the rows came back in.
--   3. FAILING THAT, BACK TO THE POOL. Domain 1 is where every account lives
--      before it belongs to anything, so it is where one returns. This is
--      precisely domain_grant run backwards.
--
-- WORKSPACE ACCESS IS NOT TOUCHED, deliberately. Hub membership lives in each
-- hub's own database and is already orthogonal to this: today one can hold
-- permission on an organisation's workspace without any privilege row in its
-- domain. Revoking that is hub_member_remove's job, and the caller's decision.
--
-- SEATS FREE THEMSELVES. _seatedIdentities counts privilege rows in the
-- domain, so deleting one releases the seat with no further bookkeeping --
-- though the caller should re-run the over-limit evaluation, since dropping
-- below a seat cap is exactly the kind of thing that lifts a clamp.
DROP PROCEDURE IF EXISTS `domain_leave`$
CREATE PROCEDURE `domain_leave`(
  IN _domain_id INT,
  IN _uid VARCHAR(16),
  IN _show_results BOOLEAN
)
proc: BEGIN
  DECLARE _is_home    TINYINT(4) DEFAULT NULL;
  DECLARE _owner      VARCHAR(16) DEFAULT NULL;
  DECLARE _successor  INT DEFAULT NULL;

  -- The pool is not an organisation and not something anyone joined.
  IF IFNULL(_domain_id, 0) <= 1 THEN
    SELECT 'INVALID_DOMAIN' AS error;
    LEAVE proc;
  END IF;

  SELECT IFNULL(is_authoritative, 0) INTO _is_home
    FROM privilege
   WHERE uid = _uid AND domain_id = _domain_id
   LIMIT 1;

  IF _is_home IS NULL THEN
    SELECT 'NOT_A_MEMBER' AS error;
    LEAVE proc;
  END IF;

  SELECT owner_id INTO _owner
    FROM organisation
   WHERE domain_id = _domain_id
   LIMIT 1;

  IF _owner IS NOT NULL AND _owner = _uid THEN
    SELECT 'OWNER_CANNOT_LEAVE' AS error;
    LEAVE proc;
  END IF;

  -- A membership that owns nothing: the row is the whole of it.
  IF _is_home <> 1 THEN
    DELETE FROM privilege WHERE uid = _uid AND domain_id = _domain_id;
    IF IFNULL(_show_results, 0) != 0 THEN
      SELECT p.* FROM privilege p WHERE p.uid = _uid;
    END IF;
    LEAVE proc;
  END IF;

  -- Home. Find somewhere for it to go.
  SELECT domain_id INTO _successor
    FROM privilege
   WHERE uid = _uid
     AND domain_id <> _domain_id
     AND domain_id <> 1
   ORDER BY privilege DESC, domain_id ASC
   LIMIT 1;

  IF _successor IS NULL THEN
    -- Back to the pool. The row may already exist -- nothing removes it except
    -- domain_grant and domain_join -- so upsert rather than assume.
    SET _successor = 1;
    INSERT INTO privilege (uid, privilege, domain_id, is_authoritative)
    VALUES (_uid, 1, 1, 1)
    ON DUPLICATE KEY UPDATE is_authoritative = 1;
  ELSE
    UPDATE privilege SET is_authoritative = 1
     WHERE uid = _uid AND domain_id = _successor;
  END IF;

  -- The identity records follow home, exactly as they did on the way in.
  UPDATE drumate SET domain_id = _successor WHERE id = _uid;
  UPDATE vhost   SET dom_id    = _successor WHERE id = _uid;
  UPDATE entity  SET dom_id    = _successor WHERE id = _uid;

  DELETE FROM privilege WHERE uid = _uid AND domain_id = _domain_id;

  -- One home, and it is the successor. Belt and braces: the row just deleted
  -- was the only other candidate, but this keeps the invariant a statement
  -- rather than an inference.
  UPDATE privilege SET is_authoritative = 0
   WHERE uid = _uid AND domain_id <> _successor;

  IF IFNULL(_show_results, 0) != 0 THEN
    SELECT p.* FROM privilege p WHERE p.uid = _uid;
  END IF;
END $

DELIMITER ;
