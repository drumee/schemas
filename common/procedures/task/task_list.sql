DELIMITER $
DROP PROCEDURE IF EXISTS `task_list`$
CREATE PROCEDURE `task_list`(
  IN _nid VARCHAR(16),
  IN _include_unscoped TINYINT
)
BEGIN
  -- Folder-scoped listing: return tasks whose nid matches the current folder
  -- node. When _include_unscoped = 1 (the workspace root view) legacy tasks
  -- with nid IS NULL are also returned, so pre-migration tasks remain visible
  -- at the root and nowhere else.
  SELECT
    t.id,
    t.title,
    t.description,
    t.status,
    t.priority,
    t.due_date,
    t.start_date,
    t.created_by,
    -- Reporter: the editable "reported by" uid. COALESCE so a row predating
    -- alter_task_add_reporter.sql (reporter_uid NULL) answers with its creator —
    -- the client never has to know the column was backfilled.
    COALESCE(t.reporter_uid, t.created_by) AS reporter_uid,
    t.nid,
    t.parent_task_id,
    t.rank,
    t.ctime,
    t.mtime,
    t.completed_at,
    GROUP_CONCAT(DISTINCT tl.label_id) AS label_ids,
    (SELECT GROUP_CONCAT(ta.uid) FROM task_assignee ta WHERE ta.task_id = t.id) AS assignee_uids,
    -- Subtask rollup counters — see task_create for the rationale. Both are
    -- covered by idx_parent_task_id (alter_task_add_parent), so they stay cheap
    -- across a whole folder's task set.
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
        AND c.is_done = 1) AS subtask_done,
    COALESCE((
      SELECT JSON_ARRAYAGG(
        JSON_OBJECT(
          'nid',       tf.file_nid,
          'filename',  m.user_filename,
          'extension', m.extension,
          'category',  m.category
        )
      )
      FROM task_file tf
      LEFT JOIN media m ON m.id = tf.file_nid
      WHERE tf.task_id = t.id
    ), JSON_ARRAY()) AS linked_files
  FROM task t
  LEFT JOIN task_label tl ON tl.task_id = t.id
  WHERE
    -- WORKSPACE SCOPE. A workspace IS a database, so "every task in this
    -- workspace" is simply "every task in this table" — no nid filter at all.
    -- Tasks stay stamped with the folder they were created in (t.nid is still
    -- returned, and the board shows it as provenance); that column just stops
    -- deciding what is VISIBLE.
    --
    -- A sentinel rather than a new parameter: MariaDB procedures take no
    -- default arguments, so a third IN would break every existing caller of a
    -- two-argument CALL. '*' is unambiguous — node ids are 16-char ascii hex —
    -- and `'*' <=> NULL` is false, so a NULL _nid still behaves exactly as
    -- before.
    _nid = '*'
     OR t.nid <=> _nid
     OR (_include_unscoped = 1 AND t.nid IS NULL)
  GROUP BY t.id
  ORDER BY
    -- Built-in columns in Kanban order first; custom-column statuses (FIELD
    -- returns 0 for values not in the list) sort AFTER them, grouped by key.
    FIELD(t.status, 'todo', 'in_progress', 'to_review', 'complete') = 0,
    FIELD(t.status, 'todo', 'in_progress', 'to_review', 'complete'),
    t.status,
    t.rank ASC,
    t.ctime ASC;
END$
DELIMITER ;
