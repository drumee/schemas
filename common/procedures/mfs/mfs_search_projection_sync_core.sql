DELIMITER $

-- =========================================================
-- mfs_search_projection_sync_core
-- =========================================================
-- Trigger-safe maintenance primitive.  The caller is already inside the
-- source mutation's transaction, so this routine deliberately contains no
-- transaction-control statement and never emits a result set.  The public
-- mfs_search_projection_sync wrapper is the interactive API; media triggers
-- call this core after INSERT/UPDATE/DELETE and advance the high-water mark
-- only after it returns successfully.
DROP PROCEDURE IF EXISTS `mfs_search_projection_sync_core`$
CREATE PROCEDURE `mfs_search_projection_sync_core`(
  IN _nid VARCHAR(16) CHARACTER SET ascii
)
main: BEGIN
  DECLARE _old_recursive_iterations INT UNSIGNED DEFAULT 1000;
  DECLARE _state VARCHAR(16) DEFAULT NULL;
  DECLARE _schema_version BIGINT UNSIGNED DEFAULT 0;
  DECLARE _projection_version BIGINT UNSIGNED DEFAULT 0;
  DECLARE _generation BIGINT UNSIGNED DEFAULT 0;
  DECLARE _mutation_high_water BIGINT UNSIGNED DEFAULT 0;
  DECLARE _reconciled_high_water BIGINT UNSIGNED DEFAULT 0;
  DECLARE _recovery_mode TINYINT UNSIGNED DEFAULT 0;
  DECLARE _source_exists TINYINT UNSIGNED DEFAULT 0;
  DECLARE _known_projection TINYINT UNSIGNED DEFAULT 0;
  DECLARE _base_path MEDIUMTEXT;
  DECLARE _current_nid VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _current_parent_id VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _current_name VARCHAR(128) CHARACTER SET utf8mb4 DEFAULT NULL;
  DECLARE _source_parent_id VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _source_name VARCHAR(128) CHARACTER SET utf8mb4 DEFAULT NULL;
  DECLARE _source_extension VARCHAR(100) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _source_mimetype VARCHAR(100) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _source_category VARCHAR(16) CHARACTER SET utf8mb4 DEFAULT NULL;
  DECLARE _source_status VARCHAR(20) CHARACTER SET utf8mb4 DEFAULT NULL;
  DECLARE _source_isalink TINYINT UNSIGNED DEFAULT 0;
  DECLARE _source_file_path VARCHAR(1000) CHARACTER SET utf8mb4 DEFAULT NULL;
  DECLARE _source_mtime INT UNSIGNED DEFAULT 0;
  DECLARE _parent_parent_id VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _parent_name VARCHAR(128) CHARACTER SET utf8mb4 DEFAULT NULL;
  DECLARE _visited MEDIUMTEXT CHARACTER SET ascii DEFAULT '';
  DECLARE _walk_depth SMALLINT UNSIGNED DEFAULT 0;
  DECLARE _level SMALLINT UNSIGNED DEFAULT 0;
  DECLARE _candidate_count BIGINT UNSIGNED DEFAULT 0;
  DECLARE _row_count BIGINT UNSIGNED DEFAULT 0;
  DECLARE _parent_path_count BIGINT UNSIGNED DEFAULT 0;
  DECLARE _parent_path_max_depth SMALLINT UNSIGNED DEFAULT 0;
  DECLARE _subtree_max_depth SMALLINT UNSIGNED DEFAULT 0;
  DECLARE _cursor_done TINYINT UNSIGNED DEFAULT 0;
  DECLARE _cursor_nid VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _cursor_parent_id VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _cursor_name VARCHAR(128) CHARACTER SET utf8mb4 DEFAULT NULL;
  DECLARE _cursor_name_fold VARCHAR(128) CHARACTER SET utf8mb4 DEFAULT NULL;
  DECLARE _cursor_extension VARCHAR(100) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _cursor_mimetype VARCHAR(100) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _cursor_category VARCHAR(16) CHARACTER SET utf8mb4 DEFAULT NULL;
  DECLARE _cursor_status VARCHAR(20) CHARACTER SET utf8mb4 DEFAULT NULL;
  DECLARE _cursor_isalink TINYINT UNSIGNED DEFAULT 0;
  DECLARE _cursor_file_path VARCHAR(1000) CHARACTER SET utf8mb4 DEFAULT NULL;
  DECLARE _cursor_mention_path MEDIUMTEXT CHARACTER SET utf8mb4;
  DECLARE _cursor_mention_path_fold MEDIUMTEXT CHARACTER SET utf8mb4;
  DECLARE _cursor_depth SMALLINT UNSIGNED DEFAULT 0;
  DECLARE _cursor_visited MEDIUMTEXT CHARACTER SET ascii;
  DECLARE _cursor_cycle_found TINYINT UNSIGNED DEFAULT 0;
  DECLARE _cursor_source_mtime INT UNSIGNED DEFAULT 0;
  DECLARE _sqlstate CHAR(5) DEFAULT '45000';
  DECLARE _errno INT DEFAULT 1644;
  DECLARE _message VARCHAR(255) DEFAULT 'SEARCH_PROJECTION_SYNC_FAILED';

  -- A cursor is a consistent-read SELECT.  The previous INSERT ... SELECT
  -- source traversal acquired shared media locks while the AFTER trigger
  -- already held the singleton state row, which inverted concurrent media
  -- writer locks.  Fetching source rows and inserting the fetched values into
  -- the temporary candidate table separately preserves authority without
  -- taking those source-row locks.
  DECLARE _subtree_cursor CURSOR FOR
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
      IF(LOCATE(CONCAT('|', child.id, '|'), t.visited) > 0, 1, 0),
      IFNULL(child.publish_time, 0)
    FROM _mfs_projection_core_subtree t
    INNER JOIN media child ON child.parent_id = t.nid
    WHERE t.depth = _level
      AND t.cycle_found = 0
    ORDER BY child.id;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _cursor_done = 1;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS CONDITION 1
      _sqlstate = RETURNED_SQLSTATE,
      _errno = MYSQL_ERRNO,
      _message = MESSAGE_TEXT;
    DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_candidates;
    DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_subtree;
    DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_old;
    DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_parent_path;
    SET SESSION max_recursive_iterations = _old_recursive_iterations;
    UPDATE mfs_search_state
    SET state = 'FAILED',
        last_error_code = CONCAT('ERR_', _errno),
        last_error_message = LEFT(_message, 255),
        finished_at = UNIX_TIMESTAMP(),
        updated_at = UNIX_TIMESTAMP()
    WHERE state_id = 1;
    RESIGNAL;
  END;

  IF _nid IS NULL OR CHAR_LENGTH(TRIM(_nid)) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SEARCH_PROJECTION_NODE_INVALID';
  END IF;

  -- READY maintenance and generation>0 BUILDING recovery both use the same
  -- current epoch.  Recovery is entered only after a prior trigger advanced
  -- the durable mutation marker without reconciling (for example, a child
  -- inserted before its parent); generation 0 still requires full rebuild.
  SELECT state, schema_version, projection_version, generation,
         mutation_high_water, reconciled_high_water
    INTO _state, _schema_version, _projection_version, _generation,
         _mutation_high_water, _reconciled_high_water
    FROM mfs_search_state
    WHERE state_id = 1;
  IF _state IS NULL
     OR _schema_version <> 1
     OR _projection_version <> 1 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'SEARCH_NAMES_PROJECTION_NOT_READY';
  END IF;

  SET _recovery_mode = IF(
    _state = 'BUILDING' AND _generation > 0
      AND _mutation_high_water > _reconciled_high_water,
    1, 0
  );
  IF NOT (
    (_state = 'READY' AND _generation > 0
      AND _mutation_high_water = _reconciled_high_water)
    OR _recovery_mode = 1
  ) THEN
    LEAVE main;
  END IF;

  SET _old_recursive_iterations = @@SESSION.max_recursive_iterations;
  IF _old_recursive_iterations < 1002 THEN
    SET SESSION max_recursive_iterations = 1002;
  END IF;

  SELECT COUNT(*) INTO _source_exists FROM media WHERE id = _nid;
  SELECT COUNT(*) INTO _known_projection
  FROM mfs_search_node
  WHERE nid = _nid AND generation = _generation;

  DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_old;
  CREATE TEMPORARY TABLE _mfs_projection_core_old (
    nid VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    PRIMARY KEY (nid)
  ) ENGINE=InnoDB;

  INSERT IGNORE INTO _mfs_projection_core_old (nid)
  SELECT descendant_nid
  FROM mfs_search_closure
  WHERE ancestor_nid = _nid AND generation = _generation;
  INSERT IGNORE INTO _mfs_projection_core_old (nid)
  SELECT nid FROM mfs_search_node
  WHERE nid = _nid AND generation = _generation;

  DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_subtree;
  CREATE TEMPORARY TABLE _mfs_projection_core_subtree (
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
    source_mtime INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (nid),
    KEY parent_id (parent_id),
    KEY depth (depth)
  ) ENGINE=InnoDB;

  IF _source_exists = 1 THEN
    -- Build the home-root-relative path by walking parents upward.  The root
    -- row itself (parent_id='0') is intentionally omitted from the path.
    SET _base_path = NULL;
    SET _current_nid = NULL;
    SET _current_parent_id = NULL;
    SET _current_name = NULL;
    SELECT id, parent_id, user_filename
      INTO _current_nid, _current_parent_id, _current_name
      FROM media WHERE id = _nid LIMIT 1;
    IF _current_nid IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SEARCH_PROJECTION_NODE_NOT_FOUND';
    END IF;
    SET _source_parent_id = _current_parent_id;
    SET _source_name = _current_name;
    SET _base_path = IFNULL(_current_name, '');
    SET _visited = CONCAT('|', _current_nid, '|');
    SET _walk_depth = 0;

    parent_walk: LOOP
      IF _current_parent_id IS NULL THEN
        IF _recovery_mode = 1 THEN
          DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_candidates;
          DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_subtree;
          DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_old;
          DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_parent_path;
          SET SESSION max_recursive_iterations = _old_recursive_iterations;
          LEAVE main;
        END IF;
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'SEARCH_PROJECTION_PARENT_NOT_FOUND';
      END IF;
      IF _current_parent_id = '0' THEN
        LEAVE parent_walk;
      END IF;
      SET _walk_depth = _walk_depth + 1;
      IF _walk_depth > 1001 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TREE_DEPTH_EXCEEDED';
      END IF;
      IF LOCATE(CONCAT('|', _current_parent_id, '|'), _visited) > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TREE_CYCLE';
      END IF;
      SET _parent_parent_id = NULL;
      SET _parent_name = NULL;
      SELECT parent_id, user_filename
        INTO _parent_parent_id, _parent_name
        FROM media
        WHERE id = _current_parent_id
        LIMIT 1;
      IF _parent_parent_id IS NULL AND NOT EXISTS (
        SELECT 1 FROM media WHERE id = _current_parent_id
      ) THEN
        IF _recovery_mode = 1 THEN
          DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_candidates;
          DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_subtree;
          DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_old;
          DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_parent_path;
          SET SESSION max_recursive_iterations = _old_recursive_iterations;
          LEAVE main;
        END IF;
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'SEARCH_PROJECTION_PARENT_NOT_FOUND';
      END IF;
      -- Do not prepend the home root's display name; all other ancestors are
      -- part of the relative path.
      IF _parent_parent_id <> '0' THEN
        SET _base_path = IF(
          _base_path = '', IFNULL(_parent_name, ''),
          CONCAT(IFNULL(_parent_name, ''), '/', _base_path)
        );
      END IF;
      SET _visited = CONCAT(_visited, _current_parent_id, '|');
      SET _current_parent_id = _parent_parent_id;
    END LOOP;

    -- Fetch the authoritative target row into local variables first.  This is
    -- a consistent-read SELECT; inserting the values separately avoids the
    -- source-row shared locks produced by INSERT ... SELECT in an AFTER
    -- trigger transaction.
    SELECT extension, mimetype, category, status, isalink, file_path,
           IFNULL(publish_time, 0)
      INTO _source_extension, _source_mimetype, _source_category,
           _source_status, _source_isalink, _source_file_path,
           _source_mtime
      FROM media
      WHERE id = _nid
      LIMIT 1;
    INSERT INTO _mfs_projection_core_subtree (
      nid, parent_id, name, name_fold, extension, mimetype, category, status,
      isalink, file_path, mention_path, mention_path_fold, depth, visited,
      cycle_found, source_mtime
    ) VALUES (
      _nid, _source_parent_id, _source_name,
      LCASE(CONVERT(IFNULL(_source_name, '') USING utf8mb4)),
      _source_extension, _source_mimetype, _source_category, _source_status,
      _source_isalink, _source_file_path,
      IF(_source_parent_id = '0', '', IFNULL(_base_path, '')),
      LCASE(IF(_source_parent_id = '0', '', IFNULL(_base_path, ''))),
      0, CAST(CONVERT(CONCAT('|', _nid, '|') USING ascii) AS CHAR(24000)),
      0, _source_mtime
    );

    SET _level = 0;
    subtree_levels: LOOP
      DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_candidates;
      CREATE TEMPORARY TABLE _mfs_projection_core_candidates LIKE _mfs_projection_core_subtree;
      -- Fetch source rows with a consistent-read cursor, then insert the
      -- fetched values.  INSERT ... SELECT from media would take shared
      -- source locks under a caller's default REPEATABLE READ transaction.
      SET _cursor_done = 0;
      OPEN _subtree_cursor;
      cursor_rows: LOOP
        FETCH _subtree_cursor INTO
          _cursor_nid, _cursor_parent_id, _cursor_name, _cursor_name_fold,
          _cursor_extension, _cursor_mimetype, _cursor_category,
          _cursor_status, _cursor_isalink, _cursor_file_path,
          _cursor_mention_path, _cursor_mention_path_fold, _cursor_depth,
          _cursor_visited, _cursor_cycle_found, _cursor_source_mtime;
        IF _cursor_done = 1 THEN
          LEAVE cursor_rows;
        END IF;
        INSERT INTO _mfs_projection_core_candidates (
          nid, parent_id, name, name_fold, extension, mimetype, category,
          status, isalink, file_path, mention_path, mention_path_fold, depth,
          visited, cycle_found, source_mtime
        ) VALUES (
          _cursor_nid, _cursor_parent_id, _cursor_name, _cursor_name_fold,
          _cursor_extension, _cursor_mimetype, _cursor_category,
          _cursor_status, _cursor_isalink, _cursor_file_path,
          _cursor_mention_path, _cursor_mention_path_fold, _cursor_depth,
          _cursor_visited, _cursor_cycle_found, _cursor_source_mtime
        );
      END LOOP;
      CLOSE _subtree_cursor;

      SELECT COUNT(*) INTO _candidate_count
      FROM _mfs_projection_core_candidates;
      IF _candidate_count = 0 THEN
        LEAVE subtree_levels;
      END IF;
      IF EXISTS (
        SELECT 1 FROM _mfs_projection_core_candidates WHERE cycle_found = 1
      ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TREE_CYCLE';
      END IF;
      -- Publish depth 1001, reject only a child beyond that frontier.
      IF _level >= 1001 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TREE_DEPTH_EXCEEDED';
      END IF;
      INSERT INTO _mfs_projection_core_subtree (
        nid, parent_id, name, name_fold, extension, mimetype, category, status,
        isalink, file_path, mention_path, mention_path_fold, depth, visited,
        cycle_found, source_mtime
      )
      SELECT c.nid, c.parent_id, c.name, c.name_fold, c.extension, c.mimetype,
             c.category, c.status, c.isalink, c.file_path, c.mention_path,
             c.mention_path_fold, c.depth, c.visited, c.cycle_found,
             c.source_mtime
      FROM _mfs_projection_core_candidates c
      LEFT JOIN _mfs_projection_core_subtree seen ON seen.nid = c.nid
      WHERE seen.nid IS NULL;
      SET _level = _level + 1;
    END LOOP;
  ELSEIF _known_projection = 0 THEN
    -- A delete for a node that was never published is already reconciled.
    DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_candidates;
    DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_subtree;
    DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_old;
    DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_parent_path;
    SET SESSION max_recursive_iterations = _old_recursive_iterations;
    LEAVE main;
  END IF;

  -- Capture the target's current projected ancestor chain before replacing
  -- its old rows.  Closure is projection-only here; unlike the previous
  -- media join, this cannot acquire a source-row lock while the AFTER trigger
  -- holds the singleton state row.
  DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_parent_path;
  CREATE TEMPORARY TABLE _mfs_projection_core_parent_path (
    ancestor_nid VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    depth SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (ancestor_nid)
  ) ENGINE=InnoDB;
  IF _source_exists = 1
     AND _source_parent_id IS NOT NULL
     AND _source_parent_id <> '0' THEN
    INSERT INTO _mfs_projection_core_parent_path (ancestor_nid, depth)
    SELECT ancestor_nid, depth
    FROM mfs_search_closure
    WHERE descendant_nid = _source_parent_id
      AND generation = _generation;
    SELECT COUNT(*), IFNULL(MAX(depth), 0)
      INTO _parent_path_count, _parent_path_max_depth
      FROM _mfs_projection_core_parent_path;
    IF _parent_path_count = 0 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'SEARCH_PROJECTION_PARENT_NOT_FOUND';
    END IF;
  END IF;

  DELETE c
  FROM mfs_search_closure c
  LEFT JOIN _mfs_projection_core_old oa ON oa.nid = c.ancestor_nid
  LEFT JOIN _mfs_projection_core_old od ON od.nid = c.descendant_nid
  WHERE oa.nid IS NOT NULL OR od.nid IS NOT NULL;
  DELETE n
  FROM mfs_search_node n
  INNER JOIN _mfs_projection_core_old old_nodes ON old_nodes.nid = n.nid;

  IF _source_exists = 1 THEN
    INSERT INTO mfs_search_node (
      nid, parent_id, name, name_fold, extension, mimetype, category, status,
      isalink, file_path, mention_path, mention_path_fold, generation,
      source_mtime
    )
    SELECT s.nid, s.parent_id, s.name, s.name_fold, s.extension, s.mimetype,
           s.category, s.status, s.isalink, s.file_path, s.mention_path,
           s.mention_path_fold, _generation, s.source_mtime
    FROM _mfs_projection_core_subtree s;

    SELECT IFNULL(MAX(depth), 0)
      INTO _subtree_max_depth
      FROM _mfs_projection_core_subtree;
    IF _source_parent_id <> '0'
       AND _parent_path_max_depth + _subtree_max_depth + 1 > 1001 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TREE_DEPTH_EXCEEDED';
    END IF;

    INSERT INTO mfs_search_closure (
      ancestor_nid, descendant_nid, depth, generation
    )
    WITH RECURSIVE subtree_walk AS (
      SELECT s.nid AS descendant_nid, s.nid AS ancestor_nid,
             CAST(0 AS UNSIGNED) AS depth, s.parent_id
      FROM _mfs_projection_core_subtree s
      UNION ALL
      SELECT w.descendant_nid, p.nid AS ancestor_nid,
             w.depth + 1 AS depth, p.parent_id
      FROM subtree_walk w
      INNER JOIN _mfs_projection_core_subtree p ON p.nid = w.parent_id
      WHERE w.parent_id IS NOT NULL
        AND w.parent_id <> '0'
        AND w.depth < 1001
    ), full_walk AS (
      SELECT ancestor_nid, descendant_nid, depth
      FROM subtree_walk
      UNION ALL
      SELECT pp.ancestor_nid, sw.descendant_nid,
             pp.depth + sw.depth + 1 AS depth
      FROM subtree_walk sw
      INNER JOIN _mfs_projection_core_parent_path pp ON 1 = 1
      WHERE sw.ancestor_nid = _nid
    )
    SELECT ancestor_nid, descendant_nid, depth, _generation
    FROM full_walk;
  END IF;

  SELECT COUNT(*) INTO _row_count FROM mfs_search_node;
  UPDATE mfs_search_state
  SET row_count = _row_count,
      updated_at = UNIX_TIMESTAMP(),
      last_error_code = NULL,
      last_error_message = NULL
  WHERE state_id = 1
    AND state IN ('READY', 'BUILDING')
    AND generation = _generation;
  DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_candidates;
  DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_subtree;
  DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_old;
  DROP TEMPORARY TABLE IF EXISTS _mfs_projection_core_parent_path;
  SET SESSION max_recursive_iterations = _old_recursive_iterations;
END$

DELIMITER ;
