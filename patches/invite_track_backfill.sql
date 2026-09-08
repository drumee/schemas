-- File: schemas/patches/invite_track_backfill.sql
-- Purpose: seed yp.invite_track with the invitation history that IS
--          recoverable, so the Viral loop page does not open reading zero on
--          an install that has been sending invitations for two years.
--
-- RE-RUNNABLE, AND SAFE IN THE MANIFEST. Every statement is INSERT IGNORE
-- against the UNIQUE (hub_id, invitee_email) key, so a second run adds
-- nothing and overwrites nothing. This is the funnel_backfill.sql contract,
-- NOT the feature_usage_backfill.sql one: that file writes absolute counters
-- with ON DUPLICATE KEY UPDATE and would reset live totals if it were ever
-- replayed, which is why it is banned from the manifest. Nothing here carries
-- a counter, so the same treatment is safe and this file IS listed.
--
-- ORDER MATTERS. The three sources are inserted best-attributed first, because
-- INSERT IGNORE means the FIRST row to claim a (hub, email) pair wins:
--
--   1. yp.token          exact. inviter_id and ctime are real, recorded at
--                        send time by _addInviteToken. approx = 0.
--   2/3. hub action_log  exact, and the ONLY source that covers the
--                        existing-account branch. Two actions: `invite_sent`
--                        (uid = inviter, address inside the log prose) and
--                        `added`/category='member' (uid = inviter, entity_id =
--                        the new member). approx = 0.
--   4. pending_invitation created_at is real but there is no inviter column,
--                        so these are approx = 1 and contribute to `sent`
--                        without contributing to `inviters`.
--
-- Running them in the other order would let a pending row with no inviter mask
-- a row that knows exactly who sent it.
--
-- WHAT CANNOT BE RECOVERED. An invitation whose workspace has since been
-- deleted, or whose audit rows were pruned: action_log is the last copy, and
-- nothing else records the sender. Those are simply absent.
--
-- WHAT SEEMS RECOVERABLE AND IS NOT: the `permission` table. A permission row
-- proves the person has access, never that they were invited, by whom, or
-- when. Do not try to infer invitations from permission.ctime -- that is the
-- grant, and treating grants as invitations would count every workspace's own
-- owner as somebody who accepted an invitation. This is a genuinely different
-- table from action_log, which does record the invitation; an earlier version
-- of this file conflated the two, concluded the existing-account branch was
-- unrecoverable, and shipped a backfill that recovered no inviter at all.
--
-- THE HAZARD IS A PRUNED SOURCE, not double-counting. yp.token rows are
-- expired and cleaned; run this as early as practical, before any retention
-- job trims them, or the recoverable history is smaller than it needed to be.
-- =========================================================================

-- ---------------------------------------------------------------
-- 1. Exact rows -- from yp.token, written by hub._addInviteToken.
--
-- method is 'hub_invite:<hub_id>', so the workspace is the part after the
-- colon; metadata.$.hub_id carries the same value and is used as the fallback
-- for any row whose method was truncated.
--
-- accept_time is derived, not stored: the token's own `status` is not reliably
-- flipped on redemption, but a drumate now existing at that address IS the
-- redemption. entity.ctime is when that account was created, which for an
-- invited newcomer is the moment they accepted.
-- ---------------------------------------------------------------
INSERT IGNORE INTO invite_track
  (inviter_id, hub_id, invitee_email, invitee_uid,
   sent_time, accept_time, had_account, source, approx)
SELECT
  t.inviter_id,
  IFNULL(NULLIF(SUBSTRING_INDEX(t.method, ':', -1), ''),
         JSON_VALUE(t.metadata, '$.hub_id'))              AS hub_id,
  LOWER(TRIM(t.email))                                    AS invitee_email,
  d.id                                                    AS invitee_uid,
  t.ctime                                                 AS sent_time,
  -- Accepted only if the account exists AND was created at or after the
  -- invitation. An older account at the same address was never a redemption
  -- of THIS invitation -- it was already there.
  IF(d.id IS NOT NULL AND e.ctime >= t.ctime, e.ctime, NULL) AS accept_time,
  0                                                       AS had_account,
  'backfill'                                              AS source,
  0                                                       AS approx
FROM token t
  LEFT JOIN drumate d ON LOWER(TRIM(d.email)) = LOWER(TRIM(t.email))
  LEFT JOIN entity  e ON e.id = d.id
WHERE t.method LIKE 'hub_invite:%'
  AND t.email IS NOT NULL
  AND TRIM(t.email) <> ''
  AND t.ctime IS NOT NULL;

-- ---------------------------------------------------------------
-- 3. Exact rows -- from each hub's own `action_log`.
--
-- THIS IS WHERE THE INVITER ACTUALLY LIVES, and an earlier version of this
-- file wrongly said it did not. The claim it made -- "a permission row proves
-- the person has access, never that they were invited, by whom, or when" -- is
-- true of `permission` and was allowed to cover `action_log`, which is a
-- different table recording exactly those three things. The other objection,
-- that a per-hub table is not cheaply aggregatable, was already answered by
-- workspace_members_backfill.sql: the same crawl visits 652 hub databases in
-- under a second.
--
-- The cost of that mistake was measurable. On stage, token was empty and every
-- surviving pending_invitation row was an invitation nobody had accepted, so
-- 100% of recovered rows carried a NULL inviter, viral_loop correctly refused
-- to count a sender nobody recorded, and the Invitee card read 0 against 209
-- real invitation events.
--
-- TWO ACTIONS, TWO BRANCHES, and between them they cover the whole of
-- hub.invite:
--
--   invite_sent               the newcomer branch. uid is the inviter,
--                             entity_id the workspace, and the invitee's
--                             address is inside the log prose.
--   added + category='member' the EXISTING-ACCOUNT branch -- the one that
--                             writes nothing anywhere else, and the reason
--                             this backfill previously recovered no inviter
--                             at all. uid is the inviter, entity_id is the
--                             new member.
--
-- `added` IS THE LOOSER OF THE TWO and is stored under its own `source` for
-- that reason. writeAudit emits it from _grantMembership, which serves
-- hub.invite's existing-account branch AND add_contributors() -- adding a
-- known contact directly, with no invitation email. Counting it is a
-- deliberate choice (it is the same act from the user's side, and excluding it
-- would leave the in-org case invisible, which is the whole bug); keeping it
-- separately labelled is what makes that choice reversible with a WHERE clause
-- instead of another backfill.
--
-- PARSING AN ADDRESS OUT OF PROSE is not something to enjoy, but the log line
-- is written by one place (hub.invite's writeAudit call) in one format, and
-- the alternative is discarding the only record of the invitation. A line that
-- does not match yields an empty string and is filtered out below rather than
-- stored as a row keyed on nothing.
--
-- ORDER MATTERS: this runs BEFORE the pending_invitation step and after the
-- token step. INSERT IGNORE means the first row to claim a (hub, email) pair
-- wins, and a row that knows its sender must beat one that does not.
-- ORDER BY ctime inside each statement extends the same rule to duplicates
-- within one log -- a workspace that re-added the same person eight times is
-- one invitation, dated the first.
-- ---------------------------------------------------------------
DELIMITER $

DROP PROCEDURE IF EXISTS `_invite_track_crawl`$
CREATE PROCEDURE `_invite_track_crawl`()
BEGIN
  DECLARE _done INT DEFAULT 0;
  DECLARE _hub_id VARCHAR(16);
  DECLARE _db     VARCHAR(255);
  DECLARE _cur CURSOR FOR
    SELECT e.id, e.db_name
      FROM entity e
     WHERE e.type = 'hub'
       AND e.area IN ('private', 'share')
       AND e.db_name IS NOT NULL
       AND e.db_name <> '';
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _done = 1;

  OPEN _cur;
  crawl: LOOP
    FETCH _cur INTO _hub_id, _db;
    IF _done = 1 THEN
      LEAVE crawl;
    END IF;

    BEGIN
      -- A hub whose database is gone, or predates action_log. yp.entity
      -- outlives the databases it names, so one stale row must not abort the
      -- crawl and leave the table half-filled.
      DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

      -- invite_sent: the address is in the prose, and acceptance is derived
      -- the same way the token step derives it -- an account existing at that
      -- address, created at or after the invitation, IS the redemption. An
      -- older account was already there and never accepted anything.
      SET @st = CONCAT(
        'INSERT IGNORE INTO invite_track ',
        '(inviter_id, hub_id, invitee_email, invitee_uid, sent_time, ',
        ' accept_time, had_account, source, approx) ',
        'SELECT s.uid, ', QUOTE(_hub_id), ', s.addr, d.id, s.ctime, ',
        '       IF(d.id IS NOT NULL AND e.ctime >= s.ctime, e.ctime, NULL), ',
        '       0, ''audit_invite_sent'', 0 ',
        -- The parse happens once, in a derived table, so the expression is
        -- written and maintained in exactly one place rather than repeated in
        -- the SELECT, the JOIN and the WHERE where three copies could drift.
        'FROM (SELECT a.uid, a.ctime, LOWER(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(',
        '        a.log, ''Invite sent to '', -1), '' for workspace'', 1))) AS addr ',
        '      FROM `', _db, '`.action_log a WHERE a.action = ''invite_sent'') s ',
        'LEFT JOIN drumate d ON LOWER(TRIM(d.email)) = s.addr ',
        'LEFT JOIN entity  e ON e.id = d.id ',
        'WHERE s.addr LIKE ''%@%'' ',
        'ORDER BY s.ctime'
      );
      PREPARE _s FROM @st;
      EXECUTE _s;
      DEALLOCATE PREPARE _s;

      -- UPGRADE, not skip. A row recovered by an earlier run of this file from
      -- pending_invitation has already claimed its (hub, email) pair, so the
      -- INSERT IGNORE above cannot touch it -- and those inviter-less rows are
      -- exactly what this source exists to replace. Guarded on approx = 1 so an
      -- exact row, or one written live by the services, is never overwritten by
      -- a replay.
      SET @st = CONCAT(
        'UPDATE invite_track t ',
        'INNER JOIN (SELECT LOWER(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(',
        '        a.log, ''Invite sent to '', -1), '' for workspace'', 1))) AS addr, ',
        '       MIN(a.uid) AS uid, MIN(a.ctime) AS ctime ',
        '     FROM `', _db, '`.action_log a WHERE a.action = ''invite_sent'' ',
        '     GROUP BY addr) s ON s.addr = t.invitee_email ',
        'SET t.inviter_id = s.uid, t.sent_time = s.ctime, ',
        '    t.source = ''audit_invite_sent'', t.approx = 0 ',
        'WHERE t.hub_id = ', QUOTE(_hub_id), ' AND t.approx = 1 AND s.addr LIKE ''%@%'''
      );
      PREPARE _s FROM @st;
      EXECUTE _s;
      DEALLOCATE PREPARE _s;

      -- added/member: the invitee is an id, so the address comes from drumate.
      -- INNER JOIN, deliberately -- a guest or deleted account has no address,
      -- and a row keyed on an empty one could never be matched by an
      -- acceptance. It would sit in invites_sent as a permanently pending
      -- invitation nobody can redeem.
      --
      -- accept_time = ctime because the grant already happened: this branch is
      -- accepted by construction, exactly as the live writer records it.
      SET @st = CONCAT(
        'INSERT IGNORE INTO invite_track ',
        '(inviter_id, hub_id, invitee_email, invitee_uid, sent_time, ',
        ' accept_time, had_account, source, approx) ',
        'SELECT a.uid, ', QUOTE(_hub_id), ', LOWER(TRIM(d.email)), a.entity_id, ',
        '       a.ctime, a.ctime, 1, ''audit_member_added'', 0 ',
        'FROM `', _db, '`.action_log a ',
        'INNER JOIN drumate d ON d.id = a.entity_id ',
        'WHERE a.action = ''added'' AND a.category = ''member'' ',
        '  AND d.email IS NOT NULL AND TRIM(d.email) <> '''' ',
        'ORDER BY a.ctime'
      );
      PREPARE _s FROM @st;
      EXECUTE _s;
      DEALLOCATE PREPARE _s;

      -- Same upgrade for the existing-account branch. accept_time is set
      -- because a grant is accepted by construction -- an approx row that had
      -- been sitting as "pending forever" is corrected to what actually
      -- happened.
      SET @st = CONCAT(
        'UPDATE invite_track t ',
        'INNER JOIN (SELECT LOWER(TRIM(d.email)) AS addr, MIN(a.uid) AS uid, ',
        '       MIN(a.entity_id) AS memb, MIN(a.ctime) AS ctime ',
        '     FROM `', _db, '`.action_log a ',
        '     INNER JOIN drumate d ON d.id = a.entity_id ',
        '     WHERE a.action = ''added'' AND a.category = ''member'' ',
        '       AND d.email IS NOT NULL AND TRIM(d.email) <> '''' ',
        '     GROUP BY addr) s ON s.addr = t.invitee_email ',
        'SET t.inviter_id = s.uid, t.invitee_uid = IFNULL(t.invitee_uid, s.memb), ',
        '    t.sent_time = s.ctime, t.accept_time = s.ctime, t.had_account = 1, ',
        '    t.source = ''audit_member_added'', t.approx = 0 ',
        'WHERE t.hub_id = ', QUOTE(_hub_id), ' AND t.approx = 1'
      );
      PREPARE _s FROM @st;
      EXECUTE _s;
      DEALLOCATE PREPARE _s;
    END;
  END LOOP;
  CLOSE _cur;
END $

DELIMITER ;

CALL _invite_track_crawl();
DROP PROCEDURE IF EXISTS `_invite_track_crawl`;

-- ---------------------------------------------------------------
-- 4. Approximate rows -- from yp.pending_invitation.
--
-- These are invitations still outstanding: the table's rows are DELETED on
-- redemption, so anything left here is by definition unaccepted, and
-- accept_time is NULL rather than derived.
--
-- No inviter column exists, so inviter_id is NULL and approx = 1. viral_loop
-- counts these in `invites_sent` but excludes them from `inviters` -- an
-- inviter that was never recorded must not become a counted one.
--
-- Rows already claimed by step 1 are skipped by INSERT IGNORE, which is the
-- intent: a token row for the same pair knows more than this one does.
-- ---------------------------------------------------------------
INSERT IGNORE INTO invite_track
  (inviter_id, hub_id, invitee_email, invitee_uid,
   sent_time, accept_time, had_account, source, approx)
SELECT
  NULL,
  p.hub_id,
  LOWER(TRIM(p.email)),
  NULL,
  -- created_at defaults to 0 on rows written before the column was added;
  -- fall back to the invitation's own expiry minus the 7-day window
  -- hub.invite uses, which is the only other timestamp the row carries.
  IF(p.created_at > 0, p.created_at, GREATEST(p.expiry_time - (7 * 86400), 0)),
  NULL,
  0,
  'backfill',
  1
FROM pending_invitation p
WHERE p.email IS NOT NULL
  AND TRIM(p.email) <> ''
  AND p.hub_id IS NOT NULL;
