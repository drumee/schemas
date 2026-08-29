DELIMITER $
DROP PROCEDURE IF EXISTS `task_rollup_parent`$
CREATE PROCEDURE `task_rollup_parent`(
  IN _id VARCHAR(16)
)
-- Labelled body so each guard can bail with LEAVE instead of nesting five IFs
-- deep. Standard MariaDB; the label on END must match.
proc_body: BEGIN
  -- Parent auto-complete. Called after a subtask's status changed: if that was
  -- the last outstanding sibling, move the PARENT into the board's done column.
  --
  -- Returns the updated parent row (same shape as task_update_status) when the
  -- rollup fired, and an EMPTY result set otherwise — the caller uses that to
  -- decide whether to log activity and broadcast.
  --
  -- Rules, in the order they are checked:
  --   1. _id must be a subtask. A top-level task rolls up nothing.
  --   2. The board must have a done column. is_done is write-once at seeding
  --      (neither column_create nor column_update accepts it), so a board has
  --      exactly ONE — the seeded 'complete' — or none at all if the user
  --      deleted it, in which case there is no way to recreate one and this
  --      no-ops forever. That matches the List checkbox, which is already inert
  --      on such a board.
  --   3. The parent must not already be in it.
  --   4. The parent's column must not sit AFTER the done column. A user can
  --      create e.g. "Released" and drag it right of Complete; completing the
  --      last subtask must not drag the parent backwards out of it.
  --   5. Every sibling must be in a done column.
  --
  -- Rollup fires only in the all-done direction. Reopening a subtask afterwards
  -- does NOT reopen the parent — that down-cascade is deliberately excluded.

  -- CHARACTER SET ascii on every id/scope variable to match the ascii columns
  -- they are compared against; without it they take the database default
  -- (utf8mb4) and raise ER_CANT_AGGREGATE_2COLLATIONS (1267).
  DECLARE _parent    VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _nid       VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _pstatus   VARCHAR(32) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _done_id   VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _done_pos  INT DEFAULT NULL;
  DECLARE _cur_pos   INT DEFAULT NULL;
  DECLARE _total     INT DEFAULT 0;
  DECLARE _finished  INT DEFAULT 0;
  DECLARE _rank      INT DEFAULT 0;
  DECLARE _now       INT DEFAULT UNIX_TIMESTAMP();

  -- 1. Resolve the parent. Nesting is one level, so the parent is never itself
  --    a subtask and there is nothing to walk up.
  SELECT parent_task_id INTO _parent FROM task WHERE id = _id;
  IF _parent IS NULL THEN
    LEAVE proc_body;
  END IF;

  -- The parent's current status. Its nid is read alongside for the row
  -- shape's sake only — the workspace has a single column set and a single
  -- rank sequence per column, so the folder no longer selects either.
  SELECT nid, CONVERT(status USING ascii)
    INTO _nid, _pstatus
    FROM task
   WHERE id = _parent;

  -- 2. The board's done column. ORDER BY position for determinism even though
  --    there can only be one.
  -- WORKSPACE SCOPE: one column set per workspace, at the root scope ''.
  -- The task's own nid (its originating folder, kept as provenance) no longer
  -- selects a column set.
  SELECT id, position
    INTO _done_id, _done_pos
    FROM task_column
   WHERE nid = ''
     AND is_done = 1
   ORDER BY position ASC
   LIMIT 1;
  IF _done_id IS NULL THEN
    LEAVE proc_body;
  END IF;

  -- 3. Already complete — nothing to do, and re-stamping completed_at would
  --    corrupt the Project Health cycle-time stats.
  IF _pstatus = _done_id THEN
    LEAVE proc_body;
  END IF;

  -- 4. Where does the parent currently sit? A status with no column row at all
  --    (an un-seeded board, or a key orphaned mid-migration) leaves _cur_pos
  --    NULL: refuse rather than guess. Not firing is a feature that quietly
  --    doesn't happen; firing wrongly moves a task the user did not touch.
  -- WORKSPACE SCOPE: root scope '' — see the done-column lookup above.
  SELECT position INTO _cur_pos
    FROM task_column
   WHERE id = _pstatus
     AND nid = ''
   LIMIT 1;
  IF _cur_pos IS NULL OR _cur_pos > _done_pos THEN
    LEAVE proc_body;
  END IF;

  -- 5. All siblings done? _total counts the parent's children including _id,
  --    whose new status is already committed by the time this runs.
  SELECT COUNT(*) INTO _total
    FROM task
   WHERE parent_task_id = _parent;

  SELECT COUNT(*) INTO _finished
    FROM task s
    JOIN task_column c
      ON c.id = CONVERT(s.status USING ascii)
     -- WORKSPACE SCOPE: the column set is the workspace's, so a task's own nid
     -- (the folder it was created in, kept as provenance) no longer selects
     -- which column it matches.
     AND c.nid = ''
   WHERE s.parent_task_id = _parent
     AND c.is_done = 1;

  IF _total = 0 OR _finished < _total THEN
    LEAVE proc_body;
  END IF;

  -- Fire. Place the parent at the bottom of the done column, exactly as
  -- task_update_status would for a manual move.
  -- WORKSPACE SCOPE: rank orders a COLUMN, and a column now holds every task
  -- in the workspace. Ranking within the task's own folder would restart the
  -- numbering per folder — a new task would land interleaved near the top of a
  -- column that already has twenty rows, instead of at its bottom.
  SELECT IFNULL(MAX(rank), 0) + 1
    INTO _rank
    FROM task
   WHERE status = CONVERT(_done_id USING utf8mb4)
     AND id <> _parent;

  UPDATE task
     SET status       = _done_id,
         rank         = _rank,
         mtime        = _now,
         completed_at = _now
   WHERE id = _parent;

  SELECT
    t.id, t.title, t.description, t.status, t.priority, t.due_date, t.start_date,
    t.created_by,
    -- Reporter: the editable "reported by" uid. COALESCE so a row predating
    -- alter_task_add_reporter.sql (reporter_uid NULL) answers with its creator —
    -- the client never has to know the column was backfilled.
    COALESCE(t.reporter_uid, t.created_by) AS reporter_uid,
    t.nid, t.parent_task_id, t.rank, t.ctime, t.mtime, t.completed_at,
    GROUP_CONCAT(DISTINCT tl.label_id) AS label_ids,
    (SELECT GROUP_CONCAT(ta.uid) FROM task_assignee ta WHERE ta.task_id = t.id) AS assignee_uids,
    (SELECT COUNT(*) FROM task s WHERE s.parent_task_id = t.id) AS subtask_total,
    (SELECT COUNT(*)
       FROM task s
       JOIN task_column c
         ON c.id = CONVERT(s.status USING ascii)
        -- WORKSPACE SCOPE: the column set is the workspace's, so a task's own nid
        -- (the folder it was created in, kept as provenance) no longer selects
        -- which column it matches.
        AND c.nid = ''
      WHERE s.parent_task_id = t.id
        AND c.is_done = 1) AS subtask_done
  FROM task t
  LEFT JOIN task_label tl ON tl.task_id = t.id
  WHERE t.id = _parent
  GROUP BY t.id;
END proc_body$
DELIMITER ;
