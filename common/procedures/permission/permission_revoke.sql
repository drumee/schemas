DELIMITER $


-- =======================================================================
--
-- =======================================================================

DROP PROCEDURE IF EXISTS `permission_revoke`$
CREATE PROCEDURE `permission_revoke`(
  IN _rid VARCHAR(16),
  IN _eid VARCHAR(16)
)
BEGIN
  DECLARE _filetype VARCHAR(160) DEFAULT NULL;
  DECLARE _is_owner_grant INT DEFAULT 0;

  -- A workspace owner's own access is not revocable.
  --
  -- desk_create_hub writes it on both sides -- permission_grant('*', owner)
  -- in the hub DB and permission_grant(hub_id, owner) in the owner's drumate
  -- DB -- and every hub-scoped service resolves privilege from it. Lose it
  -- and the owner is locked out of their own workspace: hub.invite (src
  -- 'admin', bit 16) answers PERMISSION_DENIED, and the client shows an empty
  -- response with no reason at all.
  --
  -- Found live 2026-08-11 while chasing exactly that: 7 of 566 workspaces on
  -- stage and 2 of 5197 on production had no owner grant on either side. The
  -- most recent was created 2026-05-27 -- before the 2026-07-02 dual-write
  -- fix -- and nothing newer is affected, so the known cause is closed. This
  -- guard closes the CLASS: whatever path reaches here, that one row stays.
  --
  -- Two shapes, one rule, because the grant is stored twice:
  --   hub side    resource '*' in the workspace's own DB
  --   member side resource = the hub id, in the owner's drumate DB
  -- Both ask the same question -- "is this the owner's access to their own
  -- workspace?" -- so both are matched here rather than in one caller.
  --
  -- Only the targeted single-row delete is guarded. A bare _eid ('' below)
  -- is the teardown path that clears a resource wholesale; a workspace being
  -- dismantled has no owner access left to protect, and blocking it there
  -- would strand rows in a database that is going away.
  IF _eid IS NOT NULL AND _eid != '' THEN
    IF _rid = '*' THEN
      -- Hub DB: is _eid the owner of the workspace this database belongs to?
      SELECT COUNT(*) INTO _is_owner_grant
      FROM yp.hub h
      INNER JOIN yp.entity e ON e.id = h.id
      WHERE e.db_name = DATABASE() AND h.owner_id = _eid;
    ELSE
      -- Member DB: is _rid a workspace owned by _eid?
      SELECT COUNT(*) INTO _is_owner_grant
      FROM yp.hub h
      WHERE h.id = _rid AND h.owner_id = _eid;
    END IF;
  END IF;

  IF _is_owner_grant > 0 THEN
    -- Silent no-op rather than SIGNAL: callers here are bulk member-cleanup
    -- loops that would abort mid-way on an error, leaving the other members
    -- half-removed. Skipping the one row they must not touch lets the rest of
    -- the removal finish, which is what every caller actually wants.
    DO 0;
  ELSEIF _eid != '' THEN
    DELETE FROM permission WHERE resource_id=_rid AND entity_id=_eid;
    IF _eid = 'nobody' or _eid ='*' THEN
      DELETE FROM permission WHERE resource_id=_rid and assign_via= 'link';
    END IF;
    SELECT category FROM media WHERE id=_rid INTO _filetype;
    IF _filetype='schedule' THEN
      DELETE FROM permission WHERE resource_id=_rid;
      DELETE FROM media WHERE id=_rid;
    END IF;
  ELSE
    DELETE FROM permission WHERE resource_id=_rid;
  END IF;
END $

DELIMITER ;
