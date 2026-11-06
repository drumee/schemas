DELIMITER $

-- =========================================================
-- task_reorder
-- =========================================================
-- Persist a drag-reorder of a task WITHIN its Kanban column.
--
-- _id        task being moved
-- _before_id task it now sits directly above; NULL / '' / a task that is not
--            in the same column = the bottom of the column.
--
-- The column (every task with the moved task's status, workspace-wide — see
-- task_update_status for why rank is not scoped by folder) is renumbered
-- 1..N in its CURRENT display order — rank, ctime, id, the same order
-- task_list returns — with the moved task spliced in at its new slot.
-- Renumbering rather than nudging one rank is deliberate: the
-- alter_task_add_rank backfill numbered each FOLDER from 1, so a workspace
-- column holds duplicate ranks, and "take the neighbour's rank and shift
-- everything >= it" would also push tied rows that display ABOVE the
-- neighbour below the moved card.
--
-- The status is left alone: a move into ANOTHER column is task_update_status.
--
-- Returns the column's (id, rank) pairs in their new order, so the caller can
-- adopt the new ranks without re-reading the workspace.
DROP PROCEDURE IF EXISTS `task_reorder`$
CREATE PROCEDURE `task_reorder`(
  IN _id VARCHAR(16),
  IN _before_id VARCHAR(16)
)
BEGIN
  DECLARE _status VARCHAR(20) DEFAULT NULL;
  DECLARE _slot INT DEFAULT NULL;

  SELECT status INTO _status FROM task WHERE id = _id;

  IF _status IS NOT NULL THEN
    -- 1-based position of the anchor among the column's OTHER tasks; NULL
    -- (no anchor, or the anchor is in another column) = append.
    SELECT r.rn INTO _slot
      FROM (
        SELECT id,
               ROW_NUMBER() OVER (ORDER BY rank, ctime, id) AS rn
          FROM task
         WHERE status = _status
           AND id <> _id
      ) r
     WHERE r.id = _before_id;

    -- Everyone else: their position, shifted one down from the slot onwards.
    UPDATE task t
      JOIN (
        SELECT id,
               ROW_NUMBER() OVER (ORDER BY rank, ctime, id) AS rn
          FROM task
         WHERE status = _status
           AND id <> _id
      ) r ON r.id = t.id
       SET t.rank = r.rn + IF(_slot IS NOT NULL AND r.rn >= _slot, 1, 0);

    -- The moved task takes the freed slot, or the end of the column.
    IF _slot IS NULL THEN
      SELECT COUNT(*) + 1 INTO _slot
        FROM task
       WHERE status = _status
         AND id <> _id;
    END IF;

    UPDATE task
       SET rank  = _slot,
           mtime = UNIX_TIMESTAMP()
     WHERE id = _id;
  END IF;

  SELECT id, status, rank
    FROM task
   WHERE status = _status
   ORDER BY rank, ctime, id;
END$

DELIMITER ;
