-- File: schemas/yellow_page/tables/signup_track.sql
-- Purpose: one row per signup, recording what it was attributed to at the
--          moment the account was created.
--
-- WHY THIS LIVES IN THE SCHEMAS REPO AND NOT IN analytics-server.
-- It used to sit in analytics-server/schemas/tables/, next to the dashboard
-- procedures that read it. That is where it was born and it is the wrong home,
-- because the only thing that WRITES it is loby (service/lib/loby.js
-- _trackSignup, on every account creation) -- core signup, not the dashboard.
--
-- The consequence was a production outage of exactly this table. Two facts
-- combine: no deploy step applies SQL (drumee-server-deploy and
-- drumee-server-plugin contain no reference to manifests or .sql at all), and
-- bin/patch-from-manifest derives its target from the PATH PREFIX --
-- yellow_page/ -> yp, hub/ -> hub, and so on. analytics-server manifest lists
-- its files as `tables/signup_track.sql`, which matches no prefix and prints
-- "Invalid target". So this table could never be applied by the documented
-- tooling; it reached stage on 2026-08-24 only because somebody ran the file
-- by hand, seven minutes before committing it. Production never got that hand
-- run, loby shipped the writer the same day, and every production signup since
-- has logged ER_NO_SUCH_TABLE and lost its attribution row.
--
-- invite_track, funnel_milestone and feature_usage all cite this table as the
-- design they follow, and all three correctly live here. This one now does
-- too, so a plain `bin/patch-from-manifest patches/` creates it.
--
-- WHY A TABLE AND NOT A PROFILE KEY. Attribution lived at
-- drumate.profile.$.utm, which has four problems this fixes:
--
--   it dies with the account, so a campaign's total silently shrinks every
--   time a user is deleted -- last month's number changes after the fact;
--   there is no landing URL, no auth method, no referrer;
--   nothing records WHEN attribution was decided, only when the account was
--   made, and those are the same moment only by coincidence;
--   a second visit under another campaign is invisible, because the key is
--   written once at creation and never revisited.
--
-- reward_claim and promo_launch30 both chose a table over a profile key for
-- these same reasons. This follows them.
--
-- PRIMARY KEY (uid) MAKES THE WRITE IDEMPOTENT. One signup, one row: a retried
-- create cannot double-count a campaign, which matters because the writer is
-- deliberately fire-and-forget (see loby create_account) and may be reached
-- twice.
--
-- NO FOREIGN KEY, deliberately. The row outlives the account: deleting a user
-- must not quietly reduce a campaign's historical total. That is the whole
-- point of moving off the profile.
--
-- uid is varchar(16) ascii_general_ci because yp.drumate.id is. An int, or a
-- utf8mb4 varchar, makes every join to it a cross-collation comparison and
-- raises ERROR 1267 -- utm_link carries the same note for the same reason.
--
-- CREATE TABLE IF NOT EXISTS, so this file is safe to replay and can sit in
-- patches/manifest.txt under its safety rule.
CREATE TABLE IF NOT EXISTS `signup_track` (
  `uid`      varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `email`    varchar(128) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,

  -- The four tags, as captured. NOT lowercased at rest: the readers lowercase
  -- when they group (distribution_signups does), and storing what actually
  -- arrived keeps the row an honest record of the request.
  `campaign` varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `source`   varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `medium`   varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  `content`  varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,

  -- Referral handle, so one table answers "where did this signup come from"
  -- for both attribution schemes instead of two.
  `ref`      varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,

  -- 'local' | 'google' | 'apple'. Worth its own column because OAuth signups
  -- are the ones that could not be attributed at all until now, and being able
  -- to see that split is how anyone would notice it regressing.
  `method`   varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,

  `ctime`    int(11) unsigned NOT NULL,

  PRIMARY KEY (`uid`),
  KEY `campaign` (`campaign`),
  KEY `ctime` (`ctime`),
  KEY `method` (`method`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
