DELIMITER $

-- =========================================================
-- funnel_mark
--
-- Record that a user has reached an activation milestone, for
-- the analytics Funnel page. Safe to call on every folder
-- creation and every upload: the table's PRIMARY KEY
-- (uid, milestone) makes the second and later calls no-ops,
-- so callers need no "have they already?" query and cannot
-- race each other into a double count.
--
-- CALLERS PASS ONLY 'onboarded', 'folder' OR 'upload'.
-- 'activated' is DERIVED here and nowhere else -- see below.
--
-- WHY ACTIVATED IS COMPUTED IN THIS PROCEDURE. Activation is
-- "created a folder AND uploaded a file", in either order,
-- which means it can be completed by either of two unrelated
-- code paths in server-team (media.make_dir and media.upload).
-- Asking each of them to check the other's milestone and write
-- a third row is two copies of one rule, in two handlers, that
-- drift the first time one is edited. They report the fact they
-- know; this decides what it adds up to.
--
-- Its timestamp is GREATEST(folder, upload) -- the moment the
-- SECOND leg landed, which is when the user actually became
-- activated. Taking `now` instead would date activation to
-- whichever of the two happened to be written last, and would
-- make the backfill (which replays historical events) stamp
-- every legacy user as activated on deploy day.
--
-- AN UNKNOWN MILESTONE RAISES. It does not silently no-op: the
-- callers are fire-and-forget with a .catch(warn), so a signal
-- surfaces a typo in the log, whereas a quiet skip would
-- under-count the funnel forever with nothing to notice.
-- =========================================================
DROP PROCEDURE IF EXISTS `funnel_mark`$
CREATE PROCEDURE `funnel_mark`(
  IN _uid VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  IN _milestone VARCHAR(16)
)
BEGIN
  DECLARE _folder_at INT(11) UNSIGNED DEFAULT NULL;
  DECLARE _upload_at INT(11) UNSIGNED DEFAULT NULL;

  IF _milestone NOT IN ('onboarded', 'folder', 'upload') THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'funnel_mark: milestone must be onboarded, folder or upload (activated is derived)';
  END IF;

  -- An anonymous or system actor has no funnel row to write. Not an error:
  -- media.make_dir is reachable by a DMZ guest, and a guest is not a signup.
  IF _uid IS NOT NULL AND _uid <> '' THEN

    INSERT IGNORE INTO funnel_milestone (uid, milestone, ctime)
      VALUES (_uid, _milestone, UNIX_TIMESTAMP());

    IF _milestone IN ('folder', 'upload') THEN
      SELECT ctime INTO _folder_at
        FROM funnel_milestone WHERE uid = _uid AND milestone = 'folder';
      SELECT ctime INTO _upload_at
        FROM funnel_milestone WHERE uid = _uid AND milestone = 'upload';

      IF _folder_at IS NOT NULL AND _upload_at IS NOT NULL THEN
        INSERT IGNORE INTO funnel_milestone (uid, milestone, ctime)
          VALUES (_uid, 'activated', GREATEST(_folder_at, _upload_at));
      END IF;
    END IF;

  END IF;
END $

DELIMITER ;
