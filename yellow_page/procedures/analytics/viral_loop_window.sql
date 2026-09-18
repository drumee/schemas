-- Lives HERE, not in analytics-server, because bin/patch.js resolves its target
-- database from the path prefix: `yellow_page/` means the YP database, and
-- analytics-server/schemas/procedures/yp/ matches nothing it knows (see 8a4a082).
DELIMITER $
-- =========================================================
-- viral_loop_window
--
-- The invite loop, optionally bounded.
--
-- THE INVITE FIGURES ARE GENUINELY WINDOWED. invite_track is one row per
-- invitation with its own sent_time, so invites_sent, invites_accepted, their
-- newcomer twins and `inviters` all count invitations SENT inside the range.
-- Acceptance is still attributed to the invitation's send: an invite sent in
-- March and accepted in August belongs to March, which keeps accepted a subset
-- of sent and the rate at or below 100%.
--
-- AVG TEAM SIZE CANNOT BE. workspace_members holds a CURRENT member count per
-- workspace, overwritten in place — no history to bound — so `accounts` and
-- `members` stay a snapshot of now whatever range is asked for, and the page
-- labels that pair accordingly. `users` (the invite-rate denominator) and
-- `since` stay all-time for the same reason they do in core_function_window.
-- =========================================================
DROP PROCEDURE IF EXISTS `viral_loop_window`$
CREATE PROCEDURE `viral_loop_window`(
  IN _args JSON
)
BEGIN
  DECLARE _not_test VARCHAR(255) DEFAULT NULL;

  -- Held in a variable and NULL-guarded at every use, as funnel_summary and
  -- core_function do. The guard is not decoration: `email NOT REGEXP NULL`
  -- evaluates to NULL, which is falsy, so an unset pattern would exclude EVERY
  -- user and report an empty page rather than an unfiltered one.
  DECLARE _from DATE DEFAULT NULL;
  DECLARE _to DATE DEFAULT NULL;
  DECLARE _raw_from VARCHAR(32) DEFAULT NULL;
  DECLARE _raw_to VARCHAR(32) DEFAULT NULL;

  -- Shape-gated before assignment: under STRICT_TRANS_TABLES a malformed value
  -- assigned to a DATE raises rather than reading as absent.
  SELECT JSON_VALUE(_args, "$.joined_from") INTO _raw_from;
  SELECT JSON_VALUE(_args, "$.joined_to") INTO _raw_to;
  IF _raw_from REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN SET _from = _raw_from; END IF;
  IF _raw_to REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN SET _to = _raw_to; END IF;

  SET _not_test = analytics_test_email_regexp();

  SELECT
    -- ---- Avg team size -------------------------------------------------
    -- Workspaces this install counts as collaborative. workspace_members only
    -- ever contains those (workspace_members_set refuses every other area), so
    -- no filter is repeated here -- one definition, in one place.
    (SELECT COUNT(*)          FROM workspace_members)          AS accounts,
    (SELECT IFNULL(SUM(members), 0) FROM workspace_members)    AS members,

    -- ---- Denominator for invite rate -----------------------------------
    -- Every real account. Defined exactly as in funnel_summary and
    -- core_function (and analytics-server get_env's users_real): a numerator
    -- counted over a wider population than its own denominator produces
    -- percentages over 100.
    (SELECT COUNT(*) FROM drumate d
      WHERE IF(_not_test IS NULL, 1, NOT (d.email REGEXP _not_test)))
                                                               AS users,

    -- ---- Invitees ------------------------------------------------------
    -- "Users who sent >=1 successful invite", a COUNT and not a percentage.
    -- approx rows carry no inviter and are excluded -- see the header.
    -- INNER JOIN drumate so a departed inviter, or a test account, cannot be
    -- counted in a numerator whose denominator excludes them.
    (SELECT COUNT(DISTINCT t.inviter_id)
       FROM invite_track t
       INNER JOIN drumate d2 ON d2.id = t.inviter_id
      WHERE t.approx = 0
        AND t.inviter_id IS NOT NULL
        AND IF(_not_test IS NULL, 1, NOT (d2.email REGEXP _not_test))
        AND (_from IS NULL OR t.sent_time >= UNIX_TIMESTAMP(_from)) AND (_to IS NULL OR t.sent_time < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY)))
                                                               AS inviters,

    -- ---- Sent / accepted ------------------------------------------------
    -- Counted over ALL rows including approx ones: a backfilled row is a real
    -- invitation whose sender was never recorded, so it belongs in the volume
    -- even though it cannot belong in `inviters`.
    --
    -- The invitee is filtered on the address the invitation was SENT to, not
    -- on a joined account -- most invitations have no account behind them, and
    -- an INNER JOIN here would silently drop every pending one and report an
    -- accept rate of 100%.
    (SELECT COUNT(*) FROM invite_track t
      WHERE IF(_not_test IS NULL, 1, NOT (t.invitee_email REGEXP _not_test))
        AND (_from IS NULL OR t.sent_time >= UNIX_TIMESTAMP(_from)) AND (_to IS NULL OR t.sent_time < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY)))
                                                               AS invites_sent,
    (SELECT COUNT(*) FROM invite_track t
      WHERE t.accept_time IS NOT NULL
        AND IF(_not_test IS NULL, 1, NOT (t.invitee_email REGEXP _not_test))
        AND (_from IS NULL OR t.sent_time >= UNIX_TIMESTAMP(_from)) AND (_to IS NULL OR t.sent_time < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY)))
                                                               AS invites_accepted,

    -- Newcomer-only pair: invitations that actually had to persuade somebody.
    (SELECT COUNT(*) FROM invite_track t
      WHERE t.had_account = 0
        AND IF(_not_test IS NULL, 1, NOT (t.invitee_email REGEXP _not_test))
        AND (_from IS NULL OR t.sent_time >= UNIX_TIMESTAMP(_from)) AND (_to IS NULL OR t.sent_time < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY)))
                                                               AS invites_sent_newcomer,
    (SELECT COUNT(*) FROM invite_track t
      WHERE t.had_account = 0 AND t.accept_time IS NOT NULL
        AND IF(_not_test IS NULL, 1, NOT (t.invitee_email REGEXP _not_test))
        AND (_from IS NULL OR t.sent_time >= UNIX_TIMESTAMP(_from)) AND (_to IS NULL OR t.sent_time < UNIX_TIMESTAMP(_to + INTERVAL 1 DAY)))
                                                               AS invites_accepted_newcomer,

    -- ---- Honesty ---------------------------------------------------------
    -- How many rows are backfilled stand-ins. The page prints it so a
    -- reconstructed history is not read as a measured one, and it is the cheap
    -- signal that would reveal a backfill having been run on an install where
    -- the live writers were never deployed.
    (SELECT COUNT(*) FROM invite_track WHERE approx = 1)        AS approx_rows,

    -- How far back "all time" actually reaches: the oldest invitation on
    -- record, backfilled ones included.
    --
    -- THIS USED TO EXCLUDE approx ROWS and mean "when live collection began",
    -- copied from core_function where chat and task genuinely could not be
    -- replayed. That reading died the moment invite_track_backfill.sql started
    -- crawling each hub's action_log: recovered rows are exact (approx = 0)
    -- AND reach back through history, so the old expression returned neither
    -- the start of collection nor the start of the data -- just the oldest
    -- row that happened not to come from pending_invitation. core_function hit
    -- exactly this after its own backfill crawl shipped; see the note in
    -- analytics-ui engagement.js about the caveat that became false.
    --
    -- A page captioned "all time" should be able to say how far back that is,
    -- and every row here now carries a real sent_time, so this is that. NULL
    -- means the table is empty.
    (SELECT MIN(sent_time) FROM invite_track)                   AS since;
END $

DELIMITER ;
