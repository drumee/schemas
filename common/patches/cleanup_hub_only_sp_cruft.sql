-- Cleanup: drop hub-only stored procedures that were baked into non-hub DBs
-- via factory template cruft (`hub_get_members_by_type`, `add_member`).
--
-- Background: these two SPs are only meaningful inside a genuine hub/workspace
-- DB. They were nonetheless baked into the drumate/pool factory templates and
-- have propagated into personal accounts and pre-provisioned pool instances.
-- They are dead code there (never invoked against these DBs in normal
-- operation) — but a stale 2-arg copy of hub_get_members_by_type is what
-- caused the ER_SP_WRONG_NO_OF_ARGS crash in the member-deletion flow when
-- forward_proc misrouted onto one of these DBs.
--
-- Safety: each DB checks for itself whether it is a genuine hub (i.e. has a
-- matching row in yp.hub — the same join condition show_hubs relies on, and
-- the only test confirmed to have zero false positives/negatives). If it is a
-- real hub, both drops are no-ops; only non-hub DBs carrying the stale copies
-- are cleaned. This makes the patch safe to run broadly against BOTH the
-- `drumate` and `hub` DB classes without needing per-instance targeting.
--
-- Apply against: drumate AND hub
--   bin/patch-from-file common/patches/cleanup_hub_only_sp_cruft.sql drumate
--   bin/patch-from-file common/patches/cleanup_hub_only_sp_cruft.sql hub
--
-- See: project_hub_get_members_by_type_bug (memory) / Somanos thread 2026-06-08

SET @_is_hub = (
  SELECT COUNT(*) FROM yp.entity e
  INNER JOIN yp.hub h ON h.id = e.id
  WHERE e.db_name = DATABASE()
);

SET @_drop_members_by_type = IF(@_is_hub = 0,
  'DROP PROCEDURE IF EXISTS `hub_get_members_by_type`', 'DO 0');
PREPARE _s1 FROM @_drop_members_by_type;
EXECUTE _s1;
DEALLOCATE PREPARE _s1;

SET @_drop_add_member = IF(@_is_hub = 0,
  'DROP PROCEDURE IF EXISTS `add_member`', 'DO 0');
PREPARE _s2 FROM @_drop_add_member;
EXECUTE _s2;
DEALLOCATE PREPARE _s2;
