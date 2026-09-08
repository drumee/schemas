DELIMITER $

DROP PROCEDURE IF EXISTS `hub_daily_counts`$
CREATE PROCEDURE `hub_daily_counts`(
  IN _uid VARCHAR(16),
  IN _today DATE
)
BEGIN
  -- One workspace's contribution to the once-a-day "Today you have ..." card.
  -- Returns exactly ONE row: unread_messages, due_tasks. The caller fans this
  -- out across the user's workspaces and sums, so it must stay a single cheap
  -- round trip -- never a row set the caller has to page.
  --
  -- Meetings are deliberately NOT counted here: room_list_scheduled already
  -- lists them per hub, and recurring meetings need occurrence expansion that
  -- belongs next to the client's existing expander, not in SQL.
  --
  -- Both counts are guarded on the TABLE existing, for the same reason
  -- common/patches/alter_task_column_add_is_done.sql guards its ALTER: a hub DB
  -- that predates a feature simply has no such table, and an unguarded query
  -- would raise ER_NO_SUCH_TABLE (1146). The driver swallows that and returns
  -- nothing, so the whole card would silently lose a workspace AND drop a
  -- connection -- and 1146 is what the production alert bot reports. Verified
  -- on stage: all 768 hub databases currently have all three tables, so this
  -- guard is insurance for older production hubs, not a live workaround.
  DECLARE _has_channel INT DEFAULT 0;
  DECLARE _has_task INT DEFAULT 0;

  SELECT COUNT(*) INTO _has_channel
    FROM information_schema.TABLES
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'channel';

  SELECT COUNT(*) INTO _has_task
    FROM information_schema.TABLES
   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'task';

  SET @unread := 0;
  SET @due := 0;
  SET @uid := _uid;
  SET @today := _today;

  -- Unread TEAM CHAT MESSAGES -- one per message, which is the whole point:
  -- the notification centre rolls a folder's messages up into a single row, so
  -- its count says "1" where the user has fifteen unread messages.
  --
  -- The predicates are lifted verbatim from channel_list_notifications with
  -- _type='all' and _unread_only=1, so this number and that list can never
  -- disagree. In particular the _delivered_ OR _seen_ pair is load-bearing: a
  -- member who joined after a message was posted never gets _delivered_, and
  -- gating on it alone hid messages they can genuinely read.
  SET @s := IF(_has_channel = 1,
    'SELECT COUNT(*) INTO @unread
       FROM channel c
      WHERE c.status = ''active''
        AND c.author_id != @uid
        AND (
          JSON_EXISTS(c.metadata, CONCAT("$._delivered_.", @uid)) = 1
          OR JSON_EXISTS(c.metadata, CONCAT("$._seen_.", @uid)) = 1
        )
        AND JSON_EXISTS(c.metadata, CONCAT("$._seen_.", @uid)) = 0
        AND NOT EXISTS (
          SELECT 1 FROM delete_channel dc
           WHERE dc.uid = @uid AND dc.ref_sys_id = c.sys_id
        )',
    'DO 0');
  PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

  -- DUE TASKS -- overdue OR due today, assigned to this user, not finished.
  -- due_date is a real DATE and nullable, so `<= _today` already excludes the
  -- undated; no extra NULL guard is needed or wanted.
  --
  -- "Not finished" is column-driven (is_done), never the literal status word --
  -- that is the whole point of the is_done flag. Two subtleties:
  --
  --  * LEFT JOIN, not the INNER JOIN task_list uses for subtask_done. A board
  --    that never customised a column has NO task_column rows at all (the
  --    built-ins are seeded only on first open), so an inner join would drop
  --    every task on such a board and under-count to zero.
  --  * ...which makes the no-row case a real branch, and it must fall back to
  --    the SAME defaults the client renders for an unseeded board: 'complete'
  --    is done, everything else is not. Without that fallback a finished task
  --    on an unseeded board would be reported as due.
  --
  -- Subtasks are counted like any other task: a subtask assigned to you with a
  -- due date is work that is due.
  SET @s := IF(_has_task = 1,
    'SELECT COUNT(*) INTO @due
       FROM task t
       JOIN task_assignee ta ON ta.task_id = t.id AND ta.uid = @uid
       LEFT JOIN task_column c
              ON c.id = CONVERT(t.status USING ascii)
             AND IFNULL(c.nid, '''') = IFNULL(t.nid, '''')
      WHERE t.due_date <= @today
        AND CASE
              WHEN c.id IS NULL THEN t.status <> ''complete''
              ELSE c.is_done = 0
            END',
    'DO 0');
  PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

  SELECT
    CAST(IFNULL(@unread, 0) AS UNSIGNED) AS unread_messages,
    CAST(IFNULL(@due, 0) AS UNSIGNED)    AS due_tasks;
END$

DELIMITER ;
