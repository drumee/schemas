DELIMITER $

-- =========================================================
-- mfs_search_projection_sync
-- =========================================================
-- Public maintenance facade.  Per-node sync used to lock the singleton
-- state row and then read `media`, which inverted the media-row -> state-row
-- order used by AFTER media triggers.  The already-tested rebuild owns the
-- optimistic READ COMMITTED snapshot, publication fence, high-water retry,
-- and complete source-backed image, so this facade delegates to it instead
-- of reimplementing an unsafe partial transaction.
DROP PROCEDURE IF EXISTS `mfs_search_projection_sync`$
CREATE PROCEDURE `mfs_search_projection_sync`(
  IN _nid VARCHAR(16) CHARACTER SET ascii
)
main: BEGIN
  DECLARE _source_exists TINYINT UNSIGNED DEFAULT 0;
  DECLARE _known_projection TINYINT UNSIGNED DEFAULT 0;

  IF _nid IS NULL OR CHAR_LENGTH(TRIM(_nid)) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SEARCH_PROJECTION_NODE_INVALID';
  END IF;

  -- START TRANSACTION inside an active caller transaction would implicitly
  -- commit that caller's work.  Rebuild performs its own transaction and
  -- advisory-lock handling, so reject the unsafe nesting before any state
  -- or lock side effect.
  IF @@in_transaction = 1 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'SEARCH_PROJECTION_SYNC_ACTIVE_TRANSACTION';
  END IF;

  -- Keep the historical node-not-found contract without taking a state lock
  -- around these source reads.  A stale projection row is still a valid
  -- rebuild request because the authoritative media delete must be removed.
  SELECT EXISTS (SELECT 1 FROM media WHERE id = _nid) INTO _source_exists;
  SELECT EXISTS (SELECT 1 FROM mfs_search_node WHERE nid = _nid)
    INTO _known_projection;
  IF _source_exists = 0 AND _known_projection = 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'SEARCH_PROJECTION_NODE_NOT_FOUND';
  END IF;

  -- `_nid` remains part of the public contract for compatibility.  The
  -- authoritative full rebuild is intentional: it also reconciles unrelated
  -- mutations that may have occurred while a manual sync was requested, and
  -- emits the canonical READY row/result used by maintenance callers.
  CALL mfs_search_projection_rebuild();
END$

DELIMITER ;
