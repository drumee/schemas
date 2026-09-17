-- File: schemas/patches/workspace_members_backfill.sql
-- Purpose: fill yp.workspace_members by counting the live membership of every
--          collaborative workspace, so "Avg team size" on the Viral loop page
--          is right from the first page load rather than from the next time
--          somebody happens to add a member.
--
-- ALSO THE RECONCILER, not just a seed. workspace_members_set writes absolute
-- counts, so re-running this corrects every row that drifted -- a workspace
-- whose membership changed through a path that was never instrumented, or one
-- that changed while a service was down. Safe and useful to re-run at any
-- time, and listed in the manifest for that reason.
--
-- WHY A CRAWL. Workspace membership is not in yp. It lives in each hub's OWN
-- database, in `permission` rows with resource_id = '*' -- the same rows
-- hub_get_members_by_type reads. yp.membership looks like it should hold this
-- and does not: zero rows on every install checked (2026-08-26), nothing
-- writes it. Counting members system-wide therefore means visiting every hub
-- database, which needs dynamic SQL, hence the temporary procedure below.
--
-- The precedent and its limit are both feature_usage_backfill.sql: a crawl is
-- acceptable on the WRITE side, once, and never on the read side.
-- analytics.viral_loop runs on every page load and must stay a single indexed
-- read of this table -- that is the whole reason the table exists.
--
-- WHICH HUBS. entity.type = 'hub' AND entity.area IN ('private','share'), the
-- definition analytics-server already settled on in
-- backfill_workspace_track.sql. What that excludes matters more than what it
-- includes, because the excluded rows dominate: area 'pool' (pre-allocated
-- empty shells -- 210 of this box's 216 hubs), 'dmz' (auto-hubs behind
-- meetings and share links), 'public' (system hubs: backoffice, stripe,
-- reward, Onboarding). The two hubs signup pre-creates on every desk are NOT
-- excluded here, unlike in backfill_workspace_track.sql: that file was
-- reconstructing "workspaces a user chose to create", whereas this one counts
-- workspaces that exist and have members. A pre-created workspace somebody
-- actually invited people into is a real team, and dropping it would
-- understate the average.
--
-- A MISSING DATABASE IS SKIPPED, NOT FATAL. yp.entity outlives the databases
-- it names -- an archived or half-deleted hub leaves a row behind. The handler
-- swallows those so one stale entity row cannot abort the whole crawl and
-- leave the table half-filled.
-- =========================================================================

DELIMITER $

DROP PROCEDURE IF EXISTS `_workspace_members_crawl`$
CREATE PROCEDURE `_workspace_members_crawl`()
BEGIN
  DECLARE _done INT DEFAULT 0;
  DECLARE _hub_id VARCHAR(16);
  DECLARE _cur CURSOR FOR
    SELECT e.id
      FROM entity e
     WHERE e.type = 'hub'
       AND e.area IN ('private', 'share')
       AND e.db_name IS NOT NULL
       AND e.db_name <> '';
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _done = 1;

  OPEN _cur;
  crawl: LOOP
    FETCH _cur INTO _hub_id;
    IF _done = 1 THEN
      LEAVE crawl;
    END IF;
    -- Every filter, the COUNT itself, and the missing-database handler live in
    -- workspace_members_set. This loop deliberately owns none of them: a crawl
    -- that counted for itself is a second definition of "member" that can
    -- disagree with the live writers, which is the exact drift this table
    -- exists to avoid.
    CALL workspace_members_set(_hub_id);
  END LOOP;
  CLOSE _cur;
END $

DELIMITER ;

CALL _workspace_members_crawl();
DROP PROCEDURE IF EXISTS `_workspace_members_crawl`;
