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
-- Safety: each DB checks for itself whether it is *hub-shaped* — i.e. whether
-- it carries the `article` table, which exists in all 3,234 genuine hub DBs
-- (those with a yp.hub row) and in zero sampled personal/drumate DBs. This is
-- a structural test, not a metadata test: it correctly identifies
-- pre-provisioned hub-pool instances (factory-seeded from hub.sql, sitting in
-- area='pool' awaiting assignment) as hub-shaped even though they don't yet
-- have a yp.hub row. An earlier draft of this guard used "has a yp.hub row",
-- which would have wrongly classified those pool instances as non-hub and
-- stripped their legitimate procedures — caught and corrected before deploy.
--
-- If the DB is hub-shaped, both drops are no-ops; only DBs that are NOT
-- hub-shaped (genuine drumate/personal/dmz instances carrying stale template
-- copies) are cleaned. This makes the patch safe to run broadly against BOTH
-- the `drumate` and `hub` DB classes without needing per-instance targeting.
--
-- Apply against: drumate AND hub
--   bin/patch-from-file common/patches/cleanup_hub_only_sp_cruft.sql drumate
--   bin/patch-from-file common/patches/cleanup_hub_only_sp_cruft.sql hub
--
-- See: project_hub_get_members_by_type_bug (memory) / Somanos thread 2026-06-08

SET @_is_hub_shaped = (
  SELECT COUNT(*) FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'article'
);

SET @_drop_members_by_type = IF(@_is_hub_shaped = 0,
  'DROP PROCEDURE IF EXISTS `hub_get_members_by_type`', 'DO 0');
PREPARE _s1 FROM @_drop_members_by_type;
EXECUTE _s1;
DEALLOCATE PREPARE _s1;

SET @_drop_add_member = IF(@_is_hub = 0,
  'DROP PROCEDURE IF EXISTS `add_member`', 'DO 0');
PREPARE _s2 FROM @_drop_add_member;
EXECUTE _s2;
DEALLOCATE PREPARE _s2;
