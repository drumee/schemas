DELIMITER $

-- =========================================================
-- channel_file_thread_list_in_subtree
--
-- Every active file thread on or beneath _root_nid, at any depth.
--
-- A cross-workspace move has to know this BEFORE it runs: the move deletes the
-- source media rows, and afterwards there is nothing left here to ask. Passing
-- a file nid returns at most its own thread, so callers can use this for both
-- a single file and a whole folder without branching.
--
-- Descends by parent_id rather than parent_path. parent_path is built from
-- names and is rewritten by a rename, so it cannot identify a subtree
-- reliably; parent_id is the actual edge.
--
-- Depth is capped at 64 to bound the walk. Real trees are nowhere near that,
-- and a cycle — which the schema does not prevent — would otherwise loop
-- forever inside a move.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_file_thread_list_in_subtree`$
CREATE PROCEDURE `channel_file_thread_list_in_subtree`(
  IN _root_nid VARCHAR(16)
)
main: BEGIN
  DECLARE _depth INT DEFAULT 0;
  DECLARE _added INT DEFAULT 0;

  DROP TEMPORARY TABLE IF EXISTS _subtree_nodes;
  CREATE TEMPORARY TABLE _subtree_nodes (
    nid varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    is_folder tinyint(1) NOT NULL DEFAULT 0,
    scanned tinyint(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (nid),
    KEY scan_idx (scanned, is_folder)
  ) ENGINE=MEMORY;

  INSERT IGNORE INTO _subtree_nodes (nid, is_folder, scanned)
  SELECT id, IF(category IN ('folder','hub','root'), 1, 0), 0
  FROM media
  WHERE id = _root_nid AND status NOT IN ('hidden','deleted');

  walk: LOOP
    SET _depth = _depth + 1;
    IF _depth > 64 THEN
      LEAVE walk;
    END IF;

    -- Claim the current frontier before expanding it. Marking afterwards would
    -- also mark the folders this pass just discovered, and their children would
    -- never be visited.
    DROP TEMPORARY TABLE IF EXISTS _subtree_frontier;
    CREATE TEMPORARY TABLE _subtree_frontier (
      nid varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
      PRIMARY KEY (nid)
    ) ENGINE=MEMORY
    SELECT nid FROM _subtree_nodes WHERE is_folder = 1 AND scanned = 0;

    UPDATE _subtree_nodes s
    INNER JOIN _subtree_frontier f ON f.nid = s.nid
    SET s.scanned = 1;

    INSERT IGNORE INTO _subtree_nodes (nid, is_folder, scanned)
    SELECT m.id, IF(m.category IN ('folder','hub','root'), 1, 0), 0
    FROM media m
    INNER JOIN _subtree_frontier f ON f.nid = m.parent_id
    WHERE m.status NOT IN ('hidden','deleted');
    SET _added = ROW_COUNT();

    DROP TEMPORARY TABLE IF EXISTS _subtree_frontier;

    IF _added = 0 THEN
      LEAVE walk;
    END IF;
  END LOOP;

  SELECT
    ft.file_nid,
    ft.root_message_id AS file_thread_id,
    ft.reply_count,
    m.user_filename,
    m.category
  FROM _subtree_nodes s
  INNER JOIN file_thread ft ON ft.file_nid = s.nid AND ft.status = 'active'
  INNER JOIN media m ON m.id = s.nid
  WHERE s.is_folder = 0;

  DROP TEMPORARY TABLE IF EXISTS _subtree_nodes;
END $

DELIMITER ;
