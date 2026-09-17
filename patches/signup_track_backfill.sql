-- File: schemas/patches/signup_track_backfill.sql
-- Purpose: reconstruct the signup_track rows that were never written, so the
--          Signups table does not open reading zero on an installation that
--          has been creating accounts for years.
--
-- WHY THERE IS A GAP AT ALL. loby writes one row per account creation
-- (service/lib/loby.js _trackSignup), but the table lived in the
-- analytics-server repo under a path bin/patch-from-manifest cannot target,
-- so production never had it. Every signup since the loby deploy of
-- 2026-08-24 raised ER_NO_SUCH_TABLE, and because _trackSignup swallows every
-- failure by design -- the account is already real by that line -- nothing
-- surfaced except a warning in the log. See yellow_page/tables/signup_track.sql.
--
-- RE-RUNNABLE, AND SAFE IN THE MANIFEST. One statement, INSERT IGNORE against
-- PRIMARY KEY (uid). A second run adds nothing and overwrites nothing, and a
-- row written by the LIVE writer always wins over the reconstruction of the
-- same account. This is the invite_track_backfill.sql / funnel_backfill.sql
-- contract, not the feature_usage_backfill.sql one: nothing here carries a
-- counter, so replay cannot reset a total, and the file IS listed.
--
-- ORDER: must run AFTER yellow_page/tables/signup_track.sql, which the
-- manifest guarantees.
--
-- ================= WHAT IS RECOVERABLE, AND HOW EXACTLY =================
--
-- uid, email, ctime      EXACT. drumate.id, drumate.email and entity.ctime are
--                        the same three values _trackSignup writes; the account
--                        creation timestamp IS the signup timestamp.
--
-- campaign/source/       EXACT WHERE PRESENT. create_account persists the same
-- medium/content         four tags to drumate.profile.$.utm in the same breath
--                        as the (failed) signup_track insert, so the profile
--                        key is a faithful copy of what the row would have had.
--                        NOT lowercased, matching the table's contract: the
--                        readers lowercase when they group.
--
-- ref                    EXACT WHERE PRESENT, from profile.$.ref. Already
--                        lowercased at rest -- create_account lowercases before
--                        storing -- and LOWER() here only makes that explicit.
--
-- method                 DERIVED, and the one column that is a judgement call.
--                        There is no stored record of which button was pressed,
--                        so it is inferred from yp.oauth_accounts: a google or
--                        apple row for this user, created within 120s of the
--                        account itself, means the account was made through
--                        that provider. Everything else reads 'local'.
--
--                        THE WINDOW IS LOAD-BEARING. Linking a provider to an
--                        existing local account writes exactly the same row,
--                        just later; on stage 3 of 50 oauth_accounts rows are
--                        such later links, and without the window each would
--                        turn a local signup into a fake OAuth one.
--
--                        MEASURED AGAINST GROUND TRUTH. Stage carries 61 rows
--                        written by the live writer, which knows the real
--                        answer. This expression reproduces 58 of them exactly.
--                        The 3 it misses are OAuth signups with NO
--                        oauth_accounts row at all -- nothing on disk connects
--                        them to a provider -- and they reconstruct as 'local'.
--                        That is the known and accepted error rate: ~5% of
--                        OAuth signups, 0% of local ones, and no signup is ever
--                        invented or lost, only labelled conservatively.
--
--                        'dropbox' is excluded. It is a storage link, never a
--                        way to create an account, and the method column is
--                        documented as 'local' | 'google' | 'apple'.
--
-- WHAT IS NOT RECOVERABLE, and why this file is worth running TODAY rather
-- than later: accounts that have since been DELETED. Their drumate row is
-- gone, so the signup they represent cannot be reconstructed from anything --
-- which is precisely the loss the table was created to prevent, and precisely
-- what keeps happening for as long as the writer has no table to write to.
--
-- DELIBERATELY BACKFILLS EVERY ACCOUNT, not only the attributed ones.
-- signup_track_list is a log of signups that happens to carry attribution, not
-- a log of attributed signups -- it filters on method and flags deleted
-- accounts. Restricting this to rows with a ref or a campaign would make the
-- page claim every signup ever made arrived on a campaign link.
--
-- AND IT DOES NOT DISTURB distribution_signups. That procedure unions
-- signup_track with a profile.$.utm fallback for "accounts made before the
-- table shipped", de-duplicated by NOT EXISTS on the track row. Because the
-- rows below carry the profile's utm tags ACROSS rather than inserting bare
-- rows, every signup it currently counts through the fallback branch is
-- counted, once, through the track branch afterwards. Inserting a bare row for
-- an account whose profile HAS a campaign would have done the opposite: the
-- fallback suppressed by NOT EXISTS, the track branch skipped by
-- `WHERE t.campaign IS NOT NULL`, and the signup silently absent from both.
-- =========================================================================

INSERT IGNORE INTO signup_track
  (uid, email, campaign, source, medium, content, ref, method, ctime)
SELECT
  d.id                                                              AS uid,
  -- The live column first, the profile copy as the fallback: drumate.email is
  -- what _trackSignup would have stored (profile.email is the same address at
  -- creation, but the column is the one that gets maintained).
  LEFT(NULLIF(TRIM(IFNULL(d.email, JSON_VALUE(d.profile, '$.email'))), ''), 128) AS email,
  -- Clamped to the writer's own limits (64 chars, applied in JS before the
  -- insert) so a reconstructed row cannot be wider than a live one, and so a
  -- hand-edited profile cannot raise a truncation warning here.
  LEFT(NULLIF(TRIM(JSON_VALUE(d.profile, '$.utm.utm_campaign')), ''), 64) AS campaign,
  LEFT(NULLIF(TRIM(JSON_VALUE(d.profile, '$.utm.utm_source')),   ''), 64) AS source,
  LEFT(NULLIF(TRIM(JSON_VALUE(d.profile, '$.utm.utm_medium')),   ''), 64) AS medium,
  LEFT(NULLIF(TRIM(JSON_VALUE(d.profile, '$.utm.utm_content')),  ''), 64) AS content,
  LEFT(NULLIF(LOWER(TRIM(JSON_VALUE(d.profile, '$.ref'))),       ''), 64) AS ref,
  IFNULL(
    (SELECT o.provider
       FROM yp.oauth_accounts o
      WHERE o.user_id = d.id
        AND o.provider IN ('google', 'apple')
        -- CAST both sides: ctime is UNSIGNED, and an unsigned subtraction that
        -- goes negative raises ER_DATA_OUT_OF_RANGE rather than reading as
        -- "outside the window".
        AND CAST(o.ctime AS SIGNED)
            BETWEEN CAST(e.ctime AS SIGNED) - 120 AND CAST(e.ctime AS SIGNED) + 120
      ORDER BY o.ctime
      LIMIT 1),
    'local')                                                        AS method,
  e.ctime                                                           AS ctime
FROM yp.drumate d
INNER JOIN yp.entity e ON e.id = d.id
-- Every status is kept, frozen and archived included: those accounts signed up
-- too, and signup_track is a historical record, not a list of live users.
-- ctime > 0 drops any row whose creation time was never stamped, which would
-- otherwise land in the table as a signup at the epoch.
WHERE e.ctime > 0;
