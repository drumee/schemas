-- =========================================================================
-- funnel_backfill
--
-- Seeds yp.funnel_milestone for accounts that already existed when activation
-- tracking shipped. Without it the Funnel page reads ~0% at every stage below
-- Signup on deploy day and stays wrong for as long as it takes a full signup
-- cohort to pass through -- weeks -- while the Signup box reports the whole
-- historical user base.
--
-- IDEMPOTENT. Every statement is INSERT IGNORE against PRIMARY KEY
-- (uid, milestone), so re-running changes nothing. Run it again after a
-- restore, or if a deploy is rolled back and re-applied.
--
-- ORDER MATTERS: folder and upload are seeded first, because `activated` is
-- derived from the rows they leave behind.
--
-- WHY THE DEFAULT FOLDERS NEED NO EXCLUSION CLAUSE. Every folder a new account
-- is born with -- Photos / Documents / Videos / Musics from the drumate
-- factory template, "Personal Workspace" from loby's make_default_folers, and
-- the hidden __chat__ / __trash__ trees -- is created by calling mfs_make_dir
-- procedure-to-procedure. Only the media.make_dir SERVICE writes an
-- mfs_changelog row. So the system folders were never in the source data this
-- reads, and filtering them out would be filtering out nothing. Verified on
-- stage: the only mimetype='folder' changelog rows belong to a real site
-- import, none to account provisioning.
--
-- Chat attachments are likewise absent by construction: changelog_write
-- (server-team service/media.js) returns early for any path under /__chat__/,
-- so a user who has only ever sent a file in chat has not "uploaded a file"
-- here either. That matches what the funnel means by the stage.
-- =========================================================================

-- --- Create folder -------------------------------------------------------
-- mimetype is the discriminator, not `event`: make_dir and upload BOTH write
-- event='media.new' (service/media.js), so the event alone cannot tell a
-- folder from a file.
INSERT IGNORE INTO yp.funnel_milestone (uid, milestone, ctime)
SELECT c.uid, 'folder', MIN(c.timestamp)
  FROM yp.mfs_changelog c
 INNER JOIN yp.drumate d ON d.id = c.uid
 WHERE c.event = 'media.new'
   AND JSON_VALUE(c.src, '$.mimetype') = 'folder'
 GROUP BY c.uid;

-- --- Upload file ---------------------------------------------------------
-- Everything that is not a folder. media.replace is excluded by the event
-- filter -- a replaced file is not a first upload.
INSERT IGNORE INTO yp.funnel_milestone (uid, milestone, ctime)
SELECT c.uid, 'upload', MIN(c.timestamp)
  FROM yp.mfs_changelog c
 INNER JOIN yp.drumate d ON d.id = c.uid
 WHERE c.event = 'media.new'
   AND IFNULL(JSON_VALUE(c.src, '$.mimetype'), '') <> 'folder'
 GROUP BY c.uid;

-- --- Activated -----------------------------------------------------------
-- Both legs present. Stamped with the LATER of the two, which is the moment
-- the user actually became activated -- the same rule funnel_mark applies to
-- live events, so backfilled and measured rows mean the same thing.
INSERT IGNORE INTO yp.funnel_milestone (uid, milestone, ctime)
SELECT f.uid, 'activated', GREATEST(f.ctime, u.ctime)
  FROM yp.funnel_milestone f
 INNER JOIN yp.funnel_milestone u
    ON u.uid = f.uid AND u.milestone = 'upload'
 WHERE f.milestone = 'folder';

-- --- Onboarded -----------------------------------------------------------
-- APPROXIMATE, AND MARKED AS SUCH. drumate.profile.$.onboarded is a boolean;
-- the moment the wizard was finished was never recorded anywhere, so there is
-- no real timestamp to recover. entity.ctime (signup) is the closest honest
-- stand-in: onboarding immediately follows signup for the overwhelming
-- majority of users, and it can never be LATER than the true value.
--
-- approx=1 is what keeps this from quietly becoming a fact. The dashboard
-- reports the count of approximate rows next to the stage, and any future
-- cohort or time-to-onboard analysis must exclude them rather than average
-- them in.
INSERT IGNORE INTO yp.funnel_milestone (uid, milestone, ctime, approx)
SELECT d.id, 'onboarded', e.ctime, 1
  FROM yp.drumate d
 INNER JOIN yp.entity e ON e.id = d.id
 WHERE JSON_VALUE(d.profile, '$.onboarded') IN ('1', 'true');
