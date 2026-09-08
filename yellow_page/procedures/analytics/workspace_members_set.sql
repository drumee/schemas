DELIMITER $
-- =========================================================
-- workspace_members_set
--
-- Refresh one workspace's member count in yp.workspace_members.
-- Called after anything that grants or revokes membership.
--
-- Callers (server-team):
--   hub._grantMembership     the single choke point for granting --
--                            covers invite()'s existing-account
--                            branch AND add_contributors()
--   hub.delete_contributor   after removing members
--   signup/butler._resolve_pending_invitation
--                            after redeeming pending invitations
--
-- IT COUNTS, RATHER THAN TAKING A COUNT. An earlier draft took
-- `_members` from the caller. That is one more thing four call
-- sites can each get subtly wrong -- counting before their own
-- write instead of after, or counting a different set of
-- permission rows than the crawl does -- and every such
-- disagreement shows up as an avg team size that nothing
-- contradicts. Reading the hub's own table here means the live
-- writers and workspace_members_backfill.sql cannot diverge:
-- they run the same COUNT against the same rows.
--
-- resource_id = '*' IS WHAT MEMBERSHIP MEANS. It is the
-- workspace-wide grant hub_get_members_by_type reads; every
-- other permission row is a per-node grant and counting those
-- would report a workspace of five as a workspace of ninety.
--
-- ABSOLUTE, NEVER A DELTA. A missed call costs one stale row
-- until the next mutation on that workspace, instead of an
-- offset that compounds forever, and it makes the backfill a
-- reconciler rather than a one-shot seed.
--
-- AREA AND OWNER ARE RE-READ FROM yp on every call rather than
-- passed in: they are what viral_loop filters the denominator
-- by, so they must come from the record, not from what a caller
-- believes. entity.area is the discriminator, NOT yp.area --
-- that table holds no rows for hubs on any install checked
-- (2026-08-26).
--
-- A MISSING DATABASE IS NOT AN ERROR. yp.entity outlives the
-- databases it names; an archived hub leaves a row behind. The
-- handler leaves the previous count in place rather than
-- failing the membership change that triggered this -- tracking
-- must never be able to break the thing it tracks.
-- =========================================================
DROP PROCEDURE IF EXISTS `workspace_members_set`$
CREATE PROCEDURE `workspace_members_set`(
  IN _hub_id VARCHAR(16)
)
proc_body: BEGIN
  DECLARE _now     INT(11) UNSIGNED;
  DECLARE _area    VARCHAR(20)  DEFAULT NULL;
  DECLARE _owner   VARCHAR(16)  DEFAULT NULL;
  DECLARE _db      VARCHAR(255) DEFAULT NULL;
  DECLARE _members INT(11) UNSIGNED DEFAULT 0;

  -- See the header: a hub whose database is gone must not break the caller.
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN END;

  IF _hub_id IS NULL OR _hub_id = '' THEN
    LEAVE proc_body;
  END IF;

  SET _now = UNIX_TIMESTAMP();

  SELECT e.area, e.db_name, h.owner_id
    INTO _area, _db, _owner
    FROM entity e
    LEFT JOIN hub h ON h.id = e.id
   WHERE e.id = _hub_id
     AND e.type = 'hub'
   LIMIT 1;

  -- Not a hub, or not one this page counts. Recording it would put pool
  -- shells, dmz auto-hubs and system hubs into the denominator -- see the
  -- table header for why that makes avg team size unable to move.
  IF _area IS NULL OR _area NOT IN ('private', 'share')
     OR _db IS NULL OR _db = '' THEN
    LEAVE proc_body;
  END IF;

  SET @_wm_n = 0;
  SET @_wm_st = CONCAT(
    'SELECT COUNT(DISTINCT entity_id) INTO @_wm_n FROM `', _db,
    '`.permission WHERE resource_id = ''*'''
  );
  PREPARE _wm_s FROM @_wm_st;
  EXECUTE _wm_s;
  DEALLOCATE PREPARE _wm_s;
  SET _members = IFNULL(@_wm_n, 0);

  INSERT INTO workspace_members (hub_id, owner_id, area, members, ctime, mtime)
  VALUES (_hub_id, _owner, _area, _members, _now, _now)
  ON DUPLICATE KEY UPDATE
    owner_id = _owner,
    area     = _area,
    members  = _members,
    mtime    = _now;
END proc_body $

DELIMITER ;
