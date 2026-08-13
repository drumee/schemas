-- =========================================================
-- Reconcile file_thread_lineage rows left behind by keying on the file node.
--
-- file_thread_access_reserve_direct looked a lineage up by
-- (current_hub_id, current_file_nid). A cross-hub move gives the file a new
-- node id every time it travels, so after the first move the lookup matched
-- nothing, a second lineage was inserted for the same thread, and the previous
-- row stayed parked in 'moving' with an operation id no caller would ever
-- clear. Each parked row then blocked the next move of that thread.
--
-- Twelve such rows accumulated on stage in one day across two live threads,
-- every one naming a node id that no longer exists in any database.
--
-- The procedures are now keyed on current_thread_id, which survives a move.
-- This reconciles what the old keying left behind.
--
-- Two rules, in this order:
--
--   1. A lineage whose thread does not exist in its own hub's database is not
--      a lineage. Only the hub that holds the file_thread row owns a thread;
--      a row naming a thread that lives in some other hub was written by a
--      move that half-completed. Delete it.
--
--      This is why the patch cannot simply collapse by (hub, thread): a file
--      away from home may legitimately carry its own separate thread in the
--      workspace holding it, and that thread is real — its file_thread row is
--      right there in that hub. Existence in the owning database is what
--      separates a second real thread from a leftover.
--
--   2. Among what survives, one lineage per (hub, thread) — the one with the
--      highest access_revision, which carries the real transition history.
--
-- current_file_nid is deliberately not corrected: the fixed reserve procedure
-- re-points it on the next move, and reading the right value would mean
-- querying file_thread in each hub's own database, which this patch has no
-- safe way to enumerate.
--
-- Reservations older than an hour are handed back. A move completes in
-- seconds, so anything still parked has no operation left to clear it; the
-- bound keeps a move genuinely in flight from being clobbered mid-run.
--
-- Safe to re-run. Rows in 'orphaned' are left alone: orphan handling owns
-- those, and they intentionally outlive their file.
-- =========================================================

-- Rule 1: rows whose thread is absent from their own hub's database.
--
-- Built by dynamic SQL per hub, because the file_thread table lives in each
-- hub's own schema and there is no cross-schema view of it.
DROP TEMPORARY TABLE IF EXISTS `_ftl_stale`;
CREATE TEMPORARY TABLE `_ftl_stale` (
  lineage_id VARCHAR(16) NOT NULL,
  PRIMARY KEY (lineage_id)
);

DROP PROCEDURE IF EXISTS `_ftl_collapse_once`;
DELIMITER $
CREATE PROCEDURE `_ftl_collapse_once`()
main: BEGIN
  DECLARE _done INT DEFAULT 0;
  DECLARE _hub_id VARCHAR(16);
  DECLARE _db_name VARCHAR(90);
  DECLARE hub_cursor CURSOR FOR
    SELECT DISTINCT l.current_hub_id, e.db_name
    FROM file_thread_lineage l
    INNER JOIN yp.entity e ON e.id = l.current_hub_id
    WHERE l.state <> 'orphaned'
      AND l.current_thread_id IS NOT NULL;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _done = 1;

  OPEN hub_cursor;
  hub_loop: LOOP
    FETCH hub_cursor INTO _hub_id, _db_name;
    IF _done = 1 THEN
      LEAVE hub_loop;
    END IF;

    SET @st = CONCAT(
      'INSERT IGNORE INTO `_ftl_stale` (lineage_id) ',
      'SELECT l.lineage_id FROM file_thread_lineage l ',
      'WHERE l.current_hub_id = ', QUOTE(_hub_id), ' ',
      '  AND l.state <> ''orphaned'' ',
      '  AND l.current_thread_id IS NOT NULL ',
      '  AND NOT EXISTS (SELECT 1 FROM `', REPLACE(_db_name, '`', '``'),
      '`.file_thread t WHERE t.root_message_id = l.current_thread_id)'
    );
    PREPARE stmt FROM @st;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END LOOP;
  CLOSE hub_cursor;
END $
DELIMITER ;

CALL `_ftl_collapse_once`();
DROP PROCEDURE IF EXISTS `_ftl_collapse_once`;

DELETE l FROM file_thread_lineage l
INNER JOIN `_ftl_stale` s ON s.lineage_id = l.lineage_id;

-- Rule 2: one lineage per (hub, thread) among what is left.
DROP TEMPORARY TABLE IF EXISTS `_ftl_keep`;
CREATE TEMPORARY TABLE `_ftl_keep` (
  lineage_id VARCHAR(16) NOT NULL,
  current_hub_id VARCHAR(16) NOT NULL,
  current_thread_id VARCHAR(16) NOT NULL,
  PRIMARY KEY (current_hub_id, current_thread_id)
);

INSERT INTO `_ftl_keep` (lineage_id, current_hub_id, current_thread_id)
SELECT l.lineage_id, l.current_hub_id, l.current_thread_id
FROM file_thread_lineage l
INNER JOIN (
  SELECT current_hub_id, current_thread_id,
         MAX(access_revision) AS top_revision
  FROM file_thread_lineage
  WHERE current_thread_id IS NOT NULL
    AND state <> 'orphaned'
  GROUP BY current_hub_id, current_thread_id
  HAVING COUNT(*) > 1
) w ON w.current_hub_id = l.current_hub_id
   AND w.current_thread_id = l.current_thread_id
   AND l.access_revision = w.top_revision
WHERE l.state <> 'orphaned'
GROUP BY l.current_hub_id, l.current_thread_id;

DELETE l FROM file_thread_lineage l
INNER JOIN `_ftl_keep` k
  ON k.current_hub_id = l.current_hub_id
 AND k.current_thread_id = l.current_thread_id
WHERE l.lineage_id <> k.lineage_id
  AND l.state <> 'orphaned';

-- Hand back reservations that outlived the operation holding them.
UPDATE file_thread_lineage
SET current_operation_id = NULL,
    state = 'active',
    mtime = UNIX_TIMESTAMP()
WHERE state = 'moving'
  AND mtime < UNIX_TIMESTAMP() - 3600;

DROP TEMPORARY TABLE IF EXISTS `_ftl_stale`;
DROP TEMPORARY TABLE IF EXISTS `_ftl_keep`;
