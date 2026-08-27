DELIMITER $

-- =========================================================
-- mfs_search_projection_rebuild
-- =========================================================
-- Rebuild the additive current-node and parent-closure projection from
-- `media`. Paths are accumulated in MEDIUMTEXT temporary columns so the
-- home-root-relative value is never clipped by a recursive-CTE column type.
-- READY is published only after both tables are replaced in one transaction;
-- a failed build records FAILED and never exposes partial rows.
DROP PROCEDURE IF EXISTS `mfs_search_projection_rebuild`$
CREATE PROCEDURE `mfs_search_projection_rebuild`()
main: BEGIN
  DECLARE _old_recursive_iterations INT UNSIGNED DEFAULT 1000;
  DECLARE _state VARCHAR(16) DEFAULT NULL;
  DECLARE _schema_version BIGINT UNSIGNED DEFAULT 1;
  DECLARE _projection_version BIGINT UNSIGNED DEFAULT 1;
  DECLARE _generation BIGINT UNSIGNED DEFAULT 0;
  DECLARE _next_generation BIGINT UNSIGNED DEFAULT 0;
  DECLARE _row_count BIGINT UNSIGNED DEFAULT 0;
  DECLARE _started INT UNSIGNED DEFAULT 0;
  DECLARE _previous_build_started INT UNSIGNED DEFAULT NULL;
  DECLARE _state_marked TINYINT UNSIGNED DEFAULT 0;
  DECLARE _transaction_active TINYINT UNSIGNED DEFAULT 0;
  DECLARE _level SMALLINT UNSIGNED DEFAULT 0;
  DECLARE _candidate_count BIGINT UNSIGNED DEFAULT 0;
  DECLARE _mutation_high_water BIGINT UNSIGNED DEFAULT 0;
  DECLARE _final_mutation_high_water BIGINT UNSIGNED DEFAULT 0;
  DECLARE _rebuild_attempt TINYINT UNSIGNED DEFAULT 0;
  DECLARE _max_rebuild_attempts TINYINT UNSIGNED DEFAULT 3;
  DECLARE _lock_name VARCHAR(128) DEFAULT NULL;
  DECLARE _lock_acquired TINYINT UNSIGNED DEFAULT 0;
  DECLARE _lock_result INT DEFAULT 0;
  DECLARE _sqlstate CHAR(5) DEFAULT '45000';
  DECLARE _errno INT DEFAULT 1644;
  DECLARE _message VARCHAR(255) DEFAULT 'SEARCH_PROJECTION_REBUILD_FAILED';

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS CONDITION 1
      _sqlstate = RETURNED_SQLSTATE,
      _errno = MYSQL_ERRNO,
      _message = MESSAGE_TEXT;
    DROP TEMPORARY TABLE IF EXISTS _mfs_projection_publish;
    IF _transaction_active = 1 THEN
      ROLLBACK;
      SET _transaction_active = 0;
    END IF;
    SET SESSION max_recursive_iterations = _old_recursive_iterations;
    IF _state_marked = 1 THEN
      UPDATE mfs_search_state
      SET state = 'FAILED',
          last_error_code = CONCAT('ERR_', _errno),
          last_error_message = LEFT(_message, 255),
          finished_at = UNIX_TIMESTAMP(),
          updated_at = UNIX_TIMESTAMP()
      WHERE state_id = 1;
    END IF;
    IF _lock_acquired = 1 THEN
      SELECT RELEASE_LOCK(_lock_name) INTO _lock_result;
    END IF;
    RESIGNAL;
  END;

  SET _old_recursive_iterations = @@SESSION.max_recursive_iterations;
  -- Closure uses one more iteration than the maximum supported edge depth
  -- because its self relation is the anchor. Restore the caller's value on
  -- both success and error.
  IF _old_recursive_iterations < 1002 THEN
    SET SESSION max_recursive_iterations = 1002;
  END IF;
  SET _started = UNIX_TIMESTAMP();

  -- BUILDING can be left by a trigger while a restore is assembling parents;
  -- the durable timestamp is not a live mutex.  Serialize actual rebuild
  -- callers with a connection lock so a later call can recover safely.
  SET _lock_name = CONCAT('mfs_search_projection_rebuild:', DATABASE());
  SELECT GET_LOCK(_lock_name, 0) INTO _lock_acquired;
  IF _lock_acquired <> 1 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'SEARCH_PROJECTION_REBUILD_BUSY';
  END IF;

  -- Rebuild is a top-level maintenance call and must not be nested in a
  -- caller transaction. The scan transaction below deliberately uses READ
  -- COMMITTED: MariaDB otherwise keeps shared source-row locks until the
  -- final publication fence, allowing an AFTER media trigger to hold state
  -- while waiting on a row that the scan still owns. The high-water compare
  -- is the consistency fence for the per-statement snapshots.
  IF @@in_transaction = 1 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'SEARCH_PROJECTION_REBUILD_ACTIVE_TRANSACTION';
  END IF;

  INSERT INTO mfs_search_state (
    state_id, state, schema_version, projection_version, generation,
    mutation_high_water, reconciled_high_water, row_count, updated_at
  ) VALUES (1, 'BUILDING', 1, 1, 0, 0, 0, 0, _started)
  ON DUPLICATE KEY UPDATE state_id = VALUES(state_id);

  START TRANSACTION;
  SET _transaction_active = 1;
  SELECT state, schema_version, projection_version, generation, started_at
    INTO _state, _schema_version, _projection_version, _generation,
         _previous_build_started
    FROM mfs_search_state
    WHERE state_id = 1
    FOR UPDATE;

  IF _state = 'DISABLED' THEN
    ROLLBACK;
    SET _transaction_active = 0;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SEARCH_NAMES_PROJECTION_NOT_READY';
  END IF;

  SET _started = UNIX_TIMESTAMP();
  SET _next_generation = _generation + 1;
  UPDATE mfs_search_state
  SET state = 'BUILDING',
      schema_version = 1,
      projection_version = 1,
      started_at = _started,
      finished_at = NULL,
      last_error_code = NULL,
      last_error_message = NULL,
      updated_at = _started
  WHERE state_id = 1;
  COMMIT;
  SET _transaction_active = 0;
  SET _state_marked = 1;

  -- The singleton state row is the publication/writer fence.  Source trigger
  -- execution order is storage-engine dependent, so the build never holds
  -- this state lock while it reads media.  The build is optimistic: it
  -- records a plain (non-locking) high-water snapshot under READ COMMITTED,
  -- constructs
  -- temporary rows, then acquires the state fence only at publication. The
  -- final high-water compare retries if any writer ran during the scan. No
  -- media row/range lock is held while state is locked.
  rebuild_attempts: LOOP
    SET _rebuild_attempt = _rebuild_attempt + 1;

    DROP TEMPORARY TABLE IF EXISTS _mfs_projection_publish;
    DROP TEMPORARY TABLE IF EXISTS _mfs_projection_tree;
    CREATE TEMPORARY TABLE _mfs_projection_tree (
    nid VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    parent_id VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
    name VARCHAR(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
    name_fold VARCHAR(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
    extension VARCHAR(100) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
    mimetype VARCHAR(100) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    category VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
    status VARCHAR(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
    isalink TINYINT UNSIGNED NOT NULL,
    file_path VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
    mention_path MEDIUMTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
    mention_path_fold MEDIUMTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
    depth SMALLINT UNSIGNED NOT NULL,
    visited MEDIUMTEXT CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    cycle_found TINYINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (nid),
    KEY parent_id (parent_id),
    KEY depth (depth)
    ) ENGINE=InnoDB;

    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    START TRANSACTION;
    SET _transaction_active = 1;

    -- Capture the source mutation marker without locking it. A source
    -- mutation either committed before this snapshot or will be reconciled by
    -- its AFTER trigger after publication; the final marker comparison keeps
    -- this attempt from publishing stale rows.
    SELECT mutation_high_water INTO _mutation_high_water
    FROM mfs_search_state
    WHERE state_id = 1;

  -- Home roots are anchors and intentionally have an empty relative path.
  INSERT INTO _mfs_projection_tree (
    nid, parent_id, name, name_fold, extension, mimetype, category, status,
    isalink, file_path, mention_path, mention_path_fold, depth, visited,
    cycle_found
  )
  SELECT
    m.id,
    m.parent_id,
    m.user_filename,
    LCASE(CONVERT(IFNULL(m.user_filename, '') USING utf8mb4)),
    m.extension,
    m.mimetype,
    m.category,
    m.status,
    m.isalink,
    m.file_path,
    CAST('' AS CHAR CHARACTER SET utf8mb4),
    CAST('' AS CHAR CHARACTER SET utf8mb4),
    0,
    CAST(CONVERT(CONCAT('|', m.id, '|') USING ascii) AS CHAR(24000)),
    0
  FROM media m
  WHERE m.parent_id = '0';

  SET _level = 0;
  tree_levels: LOOP
    DROP TEMPORARY TABLE IF EXISTS _mfs_projection_candidates;
    CREATE TEMPORARY TABLE _mfs_projection_candidates (
      nid VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
      parent_id VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
      name VARCHAR(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
      name_fold VARCHAR(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
      extension VARCHAR(100) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
      mimetype VARCHAR(100) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
      category VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
      status VARCHAR(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
      isalink TINYINT UNSIGNED NOT NULL,
      file_path VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
      mention_path MEDIUMTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
      mention_path_fold MEDIUMTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
      depth SMALLINT UNSIGNED NOT NULL,
      visited MEDIUMTEXT CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
      cycle_found TINYINT UNSIGNED NOT NULL DEFAULT 0,
      PRIMARY KEY (nid),
      KEY parent_id (parent_id)
    ) ENGINE=InnoDB;

    INSERT INTO _mfs_projection_candidates (
      nid, parent_id, name, name_fold, extension, mimetype, category, status,
      isalink, file_path, mention_path, mention_path_fold, depth, visited,
      cycle_found
    )
    SELECT
      child.id,
      child.parent_id,
      child.user_filename,
      LCASE(CONVERT(IFNULL(child.user_filename, '') USING utf8mb4)),
      child.extension,
      child.mimetype,
      child.category,
      child.status,
      child.isalink,
      child.file_path,
      IF(
        t.mention_path = '',
        IFNULL(child.user_filename, ''),
        CONCAT(t.mention_path, '/', IFNULL(child.user_filename, ''))
      ),
      LCASE(IF(
        t.mention_path_fold = '',
        IFNULL(child.user_filename, ''),
        CONCAT(t.mention_path_fold, '/', IFNULL(child.user_filename, ''))
      )),
      t.depth + 1,
      CONCAT(t.visited, child.id, '|'),
      IF(LOCATE(CONCAT('|', child.id, '|'), t.visited) > 0, 1, 0)
    FROM _mfs_projection_tree t
    INNER JOIN media child ON child.parent_id = t.nid
    WHERE t.depth = _level
      AND t.cycle_found = 0;

    SELECT COUNT(*) INTO _candidate_count
    FROM _mfs_projection_candidates;
    IF _candidate_count = 0 THEN
      LEAVE tree_levels;
    END IF;

    IF EXISTS (
      SELECT 1 FROM _mfs_projection_candidates WHERE cycle_found = 1
    ) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TREE_CYCLE';
    END IF;

    -- Keep the depth-1001 frontier in the published projection.  A child
    -- discovered from that frontier would be depth 1002 and is the first
    -- unsupported edge; the reader reports TREE_DEPTH_EXCEEDED only when
    -- the requested scope can actually reach a depth-1001 row.
    IF _level >= 1001 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TREE_DEPTH_EXCEEDED';
    END IF;

    INSERT INTO _mfs_projection_tree (
      nid, parent_id, name, name_fold, extension, mimetype, category, status,
      isalink, file_path, mention_path, mention_path_fold, depth, visited,
      cycle_found
    )
    SELECT
      c.nid, c.parent_id, c.name, c.name_fold, c.extension, c.mimetype,
      c.category, c.status, c.isalink, c.file_path, c.mention_path,
      c.mention_path_fold, c.depth, c.visited, c.cycle_found
    FROM _mfs_projection_candidates c
    LEFT JOIN _mfs_projection_tree seen ON seen.nid = c.nid
    WHERE seen.nid IS NULL;

    SET _level = _level + 1;
  END LOOP;

  -- A disconnected row means either a missing parent or a cycle with no root.
  -- Audit identifiers only so cycles retain their typed failure instead of
  -- being collapsed into a generic orphan error.
  IF EXISTS (
    SELECT 1
    FROM media m
    -- `media.id` is ASCII in new installs but legacy common databases may
    -- retain a utf8mb4 column.  Convert the outer key to the temporary tree's
    -- ASCII key so MariaDB can use the tree PK (the implicit opposite
    -- conversion degenerates into an O(N²) nested scan at 100k rows).
    LEFT JOIN _mfs_projection_tree t
      ON t.nid = CONVERT(m.id USING ascii)
    WHERE t.nid IS NULL
  ) THEN
    DROP TEMPORARY TABLE IF EXISTS _mfs_projection_parent_audit;
    CREATE TEMPORARY TABLE _mfs_projection_parent_audit (
      origin_nid VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
      nid VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
      parent_id VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
      depth SMALLINT UNSIGNED NOT NULL,
      visited MEDIUMTEXT CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
      cycle_found TINYINT UNSIGNED NOT NULL DEFAULT 0,
      KEY origin_nid (origin_nid),
      KEY depth (depth)
    ) ENGINE=InnoDB;

    INSERT INTO _mfs_projection_parent_audit (
      origin_nid, nid, parent_id, depth, visited, cycle_found
    )
    WITH RECURSIVE parent_audit AS (
      SELECT
        m.id AS origin_nid,
        m.id AS nid,
        m.parent_id,
        CAST(0 AS UNSIGNED) AS depth,
        CAST(CONVERT(CONCAT('|', m.id, '|') USING ascii) AS CHAR(24000))
          AS visited,
        0 AS cycle_found
      FROM media m
      LEFT JOIN _mfs_projection_tree t
        ON t.nid = CONVERT(m.id USING ascii)
      WHERE t.nid IS NULL

      UNION ALL

      SELECT
        a.origin_nid,
        p.id AS nid,
        p.parent_id,
        a.depth + 1 AS depth,
        CONCAT(a.visited, p.id, '|') AS visited,
        IF(LOCATE(CONCAT('|', p.id, '|'), a.visited) > 0, 1, 0)
          AS cycle_found
      FROM parent_audit a
      INNER JOIN media p ON p.id = a.parent_id
      WHERE a.parent_id IS NOT NULL
        AND a.parent_id <> '0'
        AND a.cycle_found = 0
        AND a.depth < 1000
    )
    SELECT origin_nid, nid, parent_id, depth, visited, cycle_found
    FROM parent_audit;

    IF EXISTS (
      SELECT 1 FROM _mfs_projection_parent_audit WHERE cycle_found = 1
    ) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TREE_CYCLE';
    END IF;

    IF EXISTS (
      SELECT 1
      FROM _mfs_projection_parent_audit a
      INNER JOIN media p ON p.id = a.parent_id
      WHERE a.depth = 1001
        AND a.parent_id IS NOT NULL
        AND a.parent_id <> '0'
    ) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TREE_DEPTH_EXCEEDED';
    END IF;

    -- A disconnected row can be a transient optimistic-snapshot race (for
    -- example, a parent/child restore committed while this attempt was
    -- scanning).  Do not take the state lock while this transaction may
    -- still hold source-row read locks: first roll back the attempt, then
    -- inspect the current high-water under a fresh lock.  A changed marker
    -- is retried; an unchanged marker is a real missing-parent failure.
    ROLLBACK;
    SET _transaction_active = 0;
    START TRANSACTION;
    SET _transaction_active = 1;
    SELECT mutation_high_water INTO _final_mutation_high_water
    FROM mfs_search_state
    WHERE state_id = 1
    FOR UPDATE;
    IF _final_mutation_high_water <> _mutation_high_water THEN
      IF _rebuild_attempt < _max_rebuild_attempts THEN
        ROLLBACK;
        SET _transaction_active = 0;
        ITERATE rebuild_attempts;
      END IF;
      ROLLBACK;
      SET _transaction_active = 0;
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'SEARCH_PROJECTION_REBUILD_RETRY';
    END IF;
    ROLLBACK;
    SET _transaction_active = 0;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SEARCH_PROJECTION_PARENT_NOT_FOUND';
  END IF;

  -- Materialize every source-backed publish field before taking the final
  -- state fence. InnoDB may acquire shared media locks for INSERT ... SELECT
  -- even in a consistent-snapshot transaction; doing this JOIN after locking
  -- state would recreate the media-row/state-row inversion. The publication
  -- phase below reads only this temporary table and projection tables.
  DROP TEMPORARY TABLE IF EXISTS _mfs_projection_publish;
  CREATE TEMPORARY TABLE _mfs_projection_publish (
    nid VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    parent_id VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
    name VARCHAR(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
    name_fold VARCHAR(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
    extension VARCHAR(100) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
    mimetype VARCHAR(100) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    category VARCHAR(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
    status VARCHAR(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
    isalink TINYINT UNSIGNED NOT NULL,
    file_path VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
    mention_path MEDIUMTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
    mention_path_fold MEDIUMTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
    source_mtime INT UNSIGNED NOT NULL,
    PRIMARY KEY (nid)
  ) ENGINE=InnoDB;
  INSERT INTO _mfs_projection_publish (
    nid, parent_id, name, name_fold, extension, mimetype, category, status,
    isalink, file_path, mention_path, mention_path_fold, source_mtime
  )
  SELECT
    t.nid, t.parent_id, t.name, t.name_fold, t.extension, t.mimetype,
    t.category, t.status, t.isalink, t.file_path, t.mention_path,
    t.mention_path_fold, IFNULL(m.publish_time, 0)
  FROM _mfs_projection_tree t
  INNER JOIN media m ON m.id = t.nid;

  -- INSERT ... SELECT can retain shared locks on source rows until the
  -- surrounding transaction ends, even though it is a consistent-snapshot
  -- read.  Close that snapshot before taking the singleton state fence;
  -- otherwise a writer that owns a media row and waits on state can deadlock
  -- with this transaction's old source-row locks.  Temporary tables survive
  -- COMMIT, so the publish image remains available to the barrier phase.
  COMMIT;
  SET _transaction_active = 0;
  START TRANSACTION;
  SET _transaction_active = 1;

  -- Final writer barrier: every trigger takes the same state row before
  -- advancing mutation_high_water. The explicit compare makes the optimistic
  -- snapshot fail closed if any writer changed the marker; retry the complete
  -- build a bounded number of times and never publish stale READY data.
  SELECT mutation_high_water INTO _final_mutation_high_water
  FROM mfs_search_state
  WHERE state_id = 1
  FOR UPDATE;
  IF _final_mutation_high_water <> _mutation_high_water THEN
    IF _rebuild_attempt < _max_rebuild_attempts THEN
      ROLLBACK;
      SET _transaction_active = 0;
      ITERATE rebuild_attempts;
    END IF;
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'SEARCH_PROJECTION_REBUILD_RETRY';
  END IF;

  DELETE FROM mfs_search_closure;
  DELETE FROM mfs_search_node;

  INSERT INTO mfs_search_node (
    nid, parent_id, name, name_fold, extension, mimetype, category, status,
    isalink, file_path, mention_path, mention_path_fold, generation, source_mtime
  )
  SELECT
    p.nid, p.parent_id, p.name, p.name_fold, p.extension, p.mimetype,
    p.category, p.status, p.isalink, p.file_path, p.mention_path,
    p.mention_path_fold, _next_generation, p.source_mtime
  FROM _mfs_projection_publish p;

  -- This CTE carries identifiers only (not paths), so its recursive column
  -- width is fixed and the 1,001-level closure does not clip text.
  INSERT INTO mfs_search_closure (
    ancestor_nid, descendant_nid, depth, generation
  )
  WITH RECURSIVE ancestor_walk AS (
    SELECT
      n.nid AS descendant_nid,
      n.nid AS ancestor_nid,
      CAST(0 AS UNSIGNED) AS depth,
      n.parent_id
    FROM _mfs_projection_tree n

    UNION ALL

    SELECT
      w.descendant_nid,
      p.nid AS ancestor_nid,
      w.depth + 1 AS depth,
      p.parent_id
    FROM ancestor_walk w
    INNER JOIN _mfs_projection_tree p ON p.nid = w.parent_id
    WHERE w.parent_id IS NOT NULL
      AND w.parent_id <> '0'
      AND w.depth < 1001
  )
  SELECT ancestor_nid, descendant_nid, depth, _next_generation
  FROM ancestor_walk;

  SELECT COUNT(*) INTO _row_count FROM mfs_search_node;
  UPDATE mfs_search_state
  SET state = 'READY',
      schema_version = 1,
      projection_version = 1,
      generation = _next_generation,
      reconciled_high_water = _mutation_high_water,
      row_count = _row_count,
      last_error_code = NULL,
      last_error_message = NULL,
      finished_at = UNIX_TIMESTAMP(),
      updated_at = UNIX_TIMESTAMP()
  WHERE state_id = 1;
  COMMIT;
  SET _transaction_active = 0;

  LEAVE rebuild_attempts;
  END LOOP;

  DROP TEMPORARY TABLE IF EXISTS _mfs_projection_publish;
  SET SESSION max_recursive_iterations = _old_recursive_iterations;
  SELECT RELEASE_LOCK(_lock_name) INTO _lock_result;
  SELECT
    'READY' AS state,
    _schema_version AS schema_version,
    _projection_version AS projection_version,
    _next_generation AS generation,
    _row_count AS row_count;
END$

DELIMITER ;
