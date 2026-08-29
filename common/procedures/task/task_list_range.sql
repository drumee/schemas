DELIMITER $
DROP PROCEDURE IF EXISTS `task_list_range`$
-- Every top-level task in THIS database whose dates overlap [_from, _to],
-- across all folders. Feeds the Personal Calendar's aggregated read
-- (calendar.list), which unions this across every workspace the caller belongs
-- to plus their own personal database — so unlike task_list there is no nid
-- filter, and the folder each task belongs to travels with the row.
--
-- Lives in `common` because the calendar reads BOTH hub databases (workspace
-- tasks) and the caller's own drumate database (personal tasks) with the same
-- call.
--
-- Excluded on purpose:
--   * subtasks (parent_task_id IS NOT NULL) — a subtask never earns its own
--     calendar cell even when its due date differs from the parent's, matching
--     the folder board's own calendar view
--   * tasks with no due_date — they have no cell to sit in
CREATE PROCEDURE `task_list_range`(
  IN _from DATE,
  IN _to DATE
)
BEGIN
  SELECT
    t.id,
    t.title,
    t.description,
    t.status,
    t.priority,
    t.due_date,
    t.start_date,
    t.nid,
    t.created_by,
    -- COALESCE so a row predating alter_task_add_reporter.sql answers with its
    -- creator rather than NULL (same contract as task_list).
    COALESCE(t.reporter_uid, t.created_by) AS reporter_uid,
    t.rank,
    t.ctime,
    t.mtime,
    t.completed_at,
    -- Folder name for the calendar's provenance pill. NULL for a workspace-root
    -- task (t.nid IS NULL); the service substitutes the workspace name there.
    m.user_filename AS folder_name,
    -- Resolved column label + theme. These have to travel WITH the row: a
    -- custom column belongs to a folder the calendar client never loads, so it
    -- could never resolve the label itself. NULL when this scope's columns were
    -- never seeded (task_column_list seeds them on a board's first open, and a
    -- personal database may have no board at all) — the client then falls back
    -- to the four built-in keys.
    --
    -- CONVERT(... USING ascii) is required: task.status is utf8mb4 while
    -- task_column.id is ascii, and comparing them raw is an illegal mix of
    -- collations. Same join task_list uses for its subtask rollup.
    c.name    AS status_label,
    c.theme   AS status_theme,
    c.is_done AS status_is_done,
    (SELECT GROUP_CONCAT(ta.uid) FROM task_assignee ta WHERE ta.task_id = t.id) AS assignee_uids
  FROM task t
  LEFT JOIN media m
         ON m.id = t.nid
  LEFT JOIN task_column c
         ON c.id = CONVERT(t.status USING ascii)
        AND c.nid = IFNULL(t.nid, '')
  WHERE t.parent_task_id IS NULL
    AND t.due_date IS NOT NULL
    -- Overlap, not containment: a duration task spans start_date..due_date and
    -- must appear in any window it touches. start_date IS NULL collapses this
    -- to the single-date test (due_date BETWEEN _from AND _to).
    AND COALESCE(t.start_date, t.due_date) <= _to
    AND t.due_date >= _from
  ORDER BY t.due_date ASC, t.rank ASC, t.ctime ASC;
END$
DELIMITER ;
