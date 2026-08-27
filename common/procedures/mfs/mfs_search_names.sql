DELIMITER $

-- =========================================================
-- mfs_search_names
-- =========================================================
-- Projection-backed scoped name search. `media` remains the mutation
-- authority; mfs_search_node/closure are accepted only from one READY epoch
-- whose high-water mark is fully reconciled. The procedure keeps the public
-- signature used by media.search_names.
DROP PROCEDURE IF EXISTS `mfs_search_names`$
CREATE PROCEDURE `mfs_search_names`(
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _scope_nid VARCHAR(16) CHARACTER SET ascii,
  IN _query VARCHAR(128),
  IN _limit TINYINT UNSIGNED
)
main: BEGIN
  DECLARE _principal VARCHAR(16) CHARACTER SET ascii;
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _area VARCHAR(50) DEFAULT NULL;
  DECLARE _scope_path MEDIUMTEXT;
  DECLARE _scope_category VARCHAR(16) DEFAULT NULL;
  DECLARE _scope_status VARCHAR(20) DEFAULT NULL;
  DECLARE _scope_isalink TINYINT UNSIGNED DEFAULT NULL;
  DECLARE _needle VARCHAR(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
  DECLARE _result_limit TINYINT UNSIGNED DEFAULT 6;
  DECLARE _now INT UNSIGNED DEFAULT 0;
  DECLARE _state VARCHAR(16) DEFAULT NULL;
  DECLARE _schema_version BIGINT UNSIGNED DEFAULT 0;
  DECLARE _projection_version BIGINT UNSIGNED DEFAULT 0;
  DECLARE _generation BIGINT UNSIGNED DEFAULT 0;
  DECLARE _mutation_high_water BIGINT UNSIGNED DEFAULT 0;
  DECLARE _reconciled_high_water BIGINT UNSIGNED DEFAULT 0;
  DECLARE _row_count BIGINT UNSIGNED DEFAULT 0;
  DECLARE _state_missing TINYINT UNSIGNED DEFAULT 0;

  DECLARE _global_permission TINYINT UNSIGNED DEFAULT 0;
  DECLARE _global_expiry INT DEFAULT 0;
  DECLARE _public_permission TINYINT UNSIGNED DEFAULT 0;
  DECLARE _public_expiry INT DEFAULT 0;
  DECLARE _scope_permission TINYINT UNSIGNED DEFAULT 0;
  DECLARE _scope_expiry INT DEFAULT 0;
  DECLARE _scope_max_depth SMALLINT UNSIGNED DEFAULT 0;
  DECLARE _has_blocked_ancestor TINYINT UNSIGNED DEFAULT 0;
  DECLARE _uniform_ready TINYINT UNSIGNED DEFAULT 0;
  DECLARE _uniform_scope_match TINYINT UNSIGNED DEFAULT 0;
  DECLARE _uniform_count BIGINT UNSIGNED DEFAULT 0;
  DECLARE _uniform_permission TINYINT UNSIGNED DEFAULT 0;
  DECLARE _uniform_expiry INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    DROP TEMPORARY TABLE IF EXISTS _mfs_search_blocked;
    DROP TEMPORARY TABLE IF EXISTS _mfs_search_access;
    DROP TEMPORARY TABLE IF EXISTS _mfs_search_public_lineage;
    DROP TEMPORARY TABLE IF EXISTS _mfs_search_principal_lineage;
    DROP TEMPORARY TABLE IF EXISTS _mfs_search_direct_grant;
    DROP TEMPORARY TABLE IF EXISTS _mfs_search_scope_nodes;
    RESIGNAL;
  END;

  IF _query IS NULL OR CHAR_LENGTH(TRIM(_query)) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SEARCH_NAMES_QUERY_INVALID';
  END IF;

  SET _principal = IF(_uid IN ('*', 'ffffffffffffffff', 'nobody'), '*', _uid);
  SET _needle = LCASE(CONVERT(TRIM(_query) USING utf8mb4));
  SET _result_limit = LEAST(GREATEST(IFNULL(_limit, 6), 1), 6);
  SET _now = UNIX_TIMESTAMP();

  -- The YP row is the trusted identity of the current common database.
  SELECT e.id, e.area
    INTO _hub_id, _area
    FROM yp.entity e
    WHERE e.db_name = DATABASE()
    LIMIT 1;
  IF _hub_id IS NULL OR _scope_nid IS NULL OR _principal IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SEARCH_NAMES_SCOPE_INVALID';
  END IF;

  -- Missing state is normalized to the same typed readiness failure as a
  -- BUILDING/FAILED/DISABLED or version/high-water mismatch.
  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42S02' SET _state_missing = 1;
    SELECT state, schema_version, projection_version, generation,
           mutation_high_water, reconciled_high_water, row_count
      INTO _state, _schema_version, _projection_version, _generation,
           _mutation_high_water, _reconciled_high_water, _row_count
      FROM mfs_search_state
      WHERE state_id = 1;
  END;
  IF _state_missing = 1
     OR _state IS NULL
     OR _state <> 'READY'
     OR _schema_version <> 1
     OR _projection_version <> 1
     OR _generation = 0
     OR _mutation_high_water <> _reconciled_high_water THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'SEARCH_NAMES_PROJECTION_NOT_READY';
  END IF;

  -- A partial generation is never joined. This also catches an interrupted
  -- manual repair even when the state row was changed incorrectly.
  IF EXISTS (
    SELECT 1 FROM mfs_search_node
    WHERE generation <> _generation
    LIMIT 1
  ) OR EXISTS (
    SELECT 1 FROM mfs_search_closure
    WHERE generation <> _generation
    LIMIT 1
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'SEARCH_NAMES_PROJECTION_NOT_READY';
  END IF;

  SELECT n.mention_path, n.category, n.status, n.isalink
    INTO _scope_path, _scope_category, _scope_status, _scope_isalink
    FROM mfs_search_node n
    WHERE n.nid = _scope_nid
      AND n.generation = _generation;
  IF _scope_category IS NULL
     OR _scope_category NOT IN ('folder', 'root')
     OR _scope_isalink <> 0
     OR _scope_status IN ('hidden', 'deleted')
     OR _scope_path REGEXP '^__(chat|trash|upload)__($|/)'
  THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SEARCH_NAMES_SCOPE_INVALID';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM mfs_search_closure c
    WHERE c.ancestor_nid = _scope_nid
      AND c.generation = _generation
      AND c.depth = 1001
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'TREE_DEPTH_EXCEEDED';
  END IF;

  DROP TEMPORARY TABLE IF EXISTS _mfs_search_scope_nodes;
  CREATE TEMPORARY TABLE _mfs_search_scope_nodes (
    nid VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    depth SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (nid),
    KEY depth (depth)
  ) ENGINE=MEMORY;
  INSERT INTO _mfs_search_scope_nodes (nid, depth)
  SELECT c.descendant_nid, c.depth
  FROM mfs_search_closure c
  WHERE c.ancestor_nid = _scope_nid
    AND c.generation = _generation;
  SELECT IFNULL(MAX(depth), 0) INTO _scope_max_depth
  FROM _mfs_search_scope_nodes;
  IF NOT EXISTS (
    SELECT 1 FROM _mfs_search_scope_nodes WHERE nid = _scope_nid
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SEARCH_NAMES_SCOPE_INVALID';
  END IF;

  IF _principal <> '*' THEN
    SELECT IFNULL(p.permission, 0), IFNULL(p.expiry_time, 0)
      INTO _global_permission, _global_expiry
    FROM permission p
    WHERE p.resource_id = '*'
      AND p.entity_id = _principal
      AND p.permission <> 0;
  END IF;

  SELECT p.permission, p.expiry_time
    INTO _public_permission, _public_expiry
  FROM permission p
  WHERE p.resource_id = '*'
    AND p.entity_id IN ('*', 'ffffffffffffffff', 'nobody')
    AND p.permission <> 0
  ORDER BY
    p.permission DESC,
    CASE p.entity_id
      WHEN '*' THEN 0
      WHEN 'ffffffffffffffff' THEN 1
      ELSE 2
    END,
    p.sys_id ASC
  LIMIT 1;

  -- Fast path for the common uniform direct scope grant.  Only grants on the
  -- requested scope/subtree can override it: permissions elsewhere in the
  -- same user's account are irrelevant, and an outer ancestor loses to this
  -- nearer direct scope grant.  Any subtree principal/public override,
  -- barrier, or global principal/public grant falls back to full precedence.
  SELECT COUNT(*),
         IFNULL(MAX(IF(
           p.resource_id = _scope_nid
           AND p.entity_id = _principal
           AND COALESCE(p.assign_via, '') NOT IN ('root', 'no_traversal'),
           1, 0
         )), 0),
         IFNULL(MAX(IF(
           p.resource_id = _scope_nid
           AND p.entity_id = _principal
           AND COALESCE(p.assign_via, '') NOT IN ('root', 'no_traversal'),
           p.permission, 0
         )), 0),
         IFNULL(MAX(IF(
           p.resource_id = _scope_nid
           AND p.entity_id = _principal
           AND COALESCE(p.assign_via, '') NOT IN ('root', 'no_traversal'),
           p.expiry_time, 0
         )), 0)
    INTO _uniform_count, _uniform_scope_match, _uniform_permission,
         _uniform_expiry
  FROM permission p
  INNER JOIN _mfs_search_scope_nodes uniform_scope
    ON uniform_scope.nid = p.resource_id
  WHERE p.entity_id IN (
    _principal, '*', 'ffffffffffffffff', 'nobody'
  )
    AND (p.permission <> 0 OR p.assign_via IN ('root', 'no_traversal'));
  IF _uniform_count = 1
     AND _uniform_scope_match = 1
     AND _global_permission = 0
     AND _public_permission = 0 THEN
    SET _uniform_ready = 1;
  END IF;

  DROP TEMPORARY TABLE IF EXISTS _mfs_search_direct_grant;
  CREATE TEMPORARY TABLE _mfs_search_direct_grant (
    nid VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    permission TINYINT UNSIGNED NOT NULL,
    expiry_time INT NOT NULL,
    assign_via VARCHAR(32) DEFAULT NULL,
    PRIMARY KEY (nid)
  ) ENGINE=MEMORY;
  IF _uniform_ready = 0 THEN
    INSERT INTO _mfs_search_direct_grant (nid, permission, expiry_time, assign_via)
    SELECT resource_id, permission, expiry_time, assign_via
    FROM (
      SELECT
        p.resource_id,
        p.permission,
        p.expiry_time,
        p.assign_via,
        ROW_NUMBER() OVER (
          PARTITION BY p.resource_id
          ORDER BY
            p.permission DESC,
            CASE
              WHEN p.entity_id = _principal THEN 0
              WHEN p.entity_id = '*' THEN 1
              WHEN p.entity_id = 'ffffffffffffffff' THEN 2
              ELSE 3
            END,
            p.sys_id ASC
        ) AS grant_rank
      FROM permission p
      INNER JOIN _mfs_search_scope_nodes sn ON sn.nid = p.resource_id
      WHERE p.entity_id IN (
        _principal, '*', 'ffffffffffffffff', 'nobody'
      )
        AND p.permission <> 0
    ) ranked
    WHERE grant_rank = 1;
  END IF;

  DROP TEMPORARY TABLE IF EXISTS _mfs_search_principal_lineage;
  CREATE TEMPORARY TABLE _mfs_search_principal_lineage (
    nid VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    permission TINYINT UNSIGNED NOT NULL,
    expiry_time INT NOT NULL,
    blocked TINYINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (nid)
  ) ENGINE=MEMORY;
  IF _principal <> '*' AND _uniform_ready = 0 THEN
    INSERT INTO _mfs_search_principal_lineage (nid, permission, expiry_time, blocked)
    SELECT descendant_nid,
           IF(assign_via IN ('root', 'no_traversal'), 0, permission),
           IF(assign_via IN ('root', 'no_traversal'), 0, expiry_time),
           IF(assign_via IN ('root', 'no_traversal'), 1, 0)
    FROM (
      SELECT
        c.descendant_nid,
        p.permission,
        p.expiry_time,
        p.assign_via,
        ROW_NUMBER() OVER (
          PARTITION BY c.descendant_nid
          ORDER BY c.depth ASC, p.sys_id ASC
        ) AS lineage_rank
      FROM _mfs_search_scope_nodes sn
      INNER JOIN mfs_search_closure c
        ON c.descendant_nid = sn.nid
       AND c.generation = _generation
       AND c.depth > 0
      INNER JOIN permission p
        ON p.resource_id = c.ancestor_nid
       AND p.entity_id = _principal
      WHERE p.permission <> 0
         OR p.assign_via IN ('root', 'no_traversal')
    ) lineage
    WHERE lineage_rank = 1;
  END IF;

  DROP TEMPORARY TABLE IF EXISTS _mfs_search_public_lineage;
  CREATE TEMPORARY TABLE _mfs_search_public_lineage (
    nid VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    permission TINYINT UNSIGNED NOT NULL,
    expiry_time INT NOT NULL,
    blocked TINYINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (nid)
  ) ENGINE=MEMORY;
  IF _uniform_ready = 0 THEN
    INSERT INTO _mfs_search_public_lineage (nid, permission, expiry_time, blocked)
    SELECT descendant_nid,
           IF(assign_via IN ('root', 'no_traversal'), 0, permission),
           IF(assign_via IN ('root', 'no_traversal'), 0, expiry_time),
           IF(assign_via IN ('root', 'no_traversal'), 1, 0)
    FROM (
      SELECT
        c.descendant_nid,
        p.permission,
        p.expiry_time,
        p.assign_via,
        ROW_NUMBER() OVER (
          PARTITION BY c.descendant_nid
          ORDER BY c.depth ASC, p.sys_id ASC
        ) AS lineage_rank
      FROM _mfs_search_scope_nodes sn
      INNER JOIN mfs_search_closure c
        ON c.descendant_nid = sn.nid
       AND c.generation = _generation
       AND c.depth > 0
      INNER JOIN permission p
        ON p.resource_id = c.ancestor_nid
       AND p.entity_id = '*'
      WHERE p.permission <> 0
         OR p.assign_via IN ('root', 'no_traversal')
    ) lineage
    WHERE lineage_rank = 1;
  END IF;

  DROP TEMPORARY TABLE IF EXISTS _mfs_search_access;
  CREATE TEMPORARY TABLE _mfs_search_access (
    nid VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    permission TINYINT UNSIGNED NOT NULL,
    expiry_time INT NOT NULL,
    PRIMARY KEY (nid)
  ) ENGINE=MEMORY;
  IF _uniform_ready = 1 THEN
    INSERT INTO _mfs_search_access (nid, permission, expiry_time)
    SELECT nid, _uniform_permission, _uniform_expiry
    FROM _mfs_search_scope_nodes;
  ELSE
    INSERT INTO _mfs_search_access (nid, permission, expiry_time)
    SELECT
      sn.nid,
      CASE
        WHEN _global_permission <> 0 THEN _global_permission
        WHEN dg.permission IS NOT NULL THEN dg.permission
        WHEN IFNULL(pl.permission, 0) >= IFNULL(wl.permission, 0)
         AND IFNULL(pl.permission, 0) <> 0 THEN pl.permission
        WHEN IFNULL(wl.permission, 0) <> 0 THEN wl.permission
        ELSE _public_permission
      END,
      CASE
        WHEN _global_permission <> 0 THEN _global_expiry
        WHEN dg.permission IS NOT NULL THEN dg.expiry_time
        WHEN IFNULL(pl.permission, 0) >= IFNULL(wl.permission, 0)
         AND IFNULL(pl.permission, 0) <> 0 THEN pl.expiry_time
        WHEN IFNULL(wl.permission, 0) <> 0 THEN wl.expiry_time
        ELSE _public_expiry
      END
    FROM _mfs_search_scope_nodes sn
    LEFT JOIN _mfs_search_direct_grant dg ON dg.nid = sn.nid
    LEFT JOIN _mfs_search_principal_lineage pl ON pl.nid = sn.nid
    LEFT JOIN _mfs_search_public_lineage wl ON wl.nid = sn.nid;
  END IF;

  SELECT permission, expiry_time
    INTO _scope_permission, _scope_expiry
  FROM _mfs_search_access
  WHERE nid = _scope_nid;
  IF (_scope_permission & 2) <> 2
     OR (_scope_expiry <> 0 AND _scope_expiry <= _now) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SEARCH_NAMES_SCOPE_INVALID';
  END IF;

  DROP TEMPORARY TABLE IF EXISTS _mfs_search_blocked;
  CREATE TEMPORARY TABLE _mfs_search_blocked (
    nid VARCHAR(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
    PRIMARY KEY (nid)
  ) ENGINE=InnoDB;

  -- A flat folder has no strict intermediate ancestor beyond its validated
  -- scope root, so avoid scanning its closure a second time.  For a deeper
  -- scope, first look for an invalid node that can actually have descendants;
  -- only then materialize each blocked descendant once.
  IF _scope_max_depth > 1 THEN
    SELECT EXISTS (
      SELECT 1
      FROM _mfs_search_scope_nodes candidate_scope
      INNER JOIN mfs_search_node candidate_node
        ON candidate_node.nid = candidate_scope.nid
       AND candidate_node.generation = _generation
      INNER JOIN _mfs_search_access candidate_access
        ON candidate_access.nid = candidate_scope.nid
      WHERE candidate_scope.depth > 0
        AND candidate_scope.depth < _scope_max_depth
        AND (
          candidate_node.status IN ('hidden', 'deleted')
          OR (
            candidate_node.nid <> _scope_nid
            AND candidate_node.category <> 'folder'
          )
          OR candidate_node.isalink <> 0
          OR candidate_node.mention_path REGEXP '^__(chat|trash|upload)__($|/)'
          OR (candidate_access.permission & 2) <> 2
          OR (
            candidate_access.expiry_time <> 0
            AND candidate_access.expiry_time <= _now
          )
        )
    ) INTO _has_blocked_ancestor;
  END IF;

  IF _has_blocked_ancestor = 1 THEN
    INSERT IGNORE INTO _mfs_search_blocked (nid)
    SELECT path.descendant_nid
    FROM mfs_search_closure path
    INNER JOIN _mfs_search_scope_nodes path_scope
      ON path_scope.nid = path.ancestor_nid
    INNER JOIN mfs_search_node ancestor_node
      ON ancestor_node.nid = path.ancestor_nid
     AND ancestor_node.generation = _generation
    INNER JOIN _mfs_search_access ancestor_access
      ON ancestor_access.nid = path.ancestor_nid
    WHERE path.generation = _generation
      AND path.depth > 0
      AND (
        ancestor_node.status IN ('hidden', 'deleted')
        OR (
          ancestor_node.nid <> _scope_nid
          AND ancestor_node.category <> 'folder'
        )
        OR ancestor_node.isalink <> 0
        OR ancestor_node.mention_path REGEXP '^__(chat|trash|upload)__($|/)'
        OR (ancestor_access.permission & 2) <> 2
        OR (
          ancestor_access.expiry_time <> 0
          AND ancestor_access.expiry_time <= _now
        )
      );
  END IF;

  -- Scope-relative paths are the contract width. The stored home-relative
  -- MEDIUMTEXT value remains complete; only an accessible traversal overflow
  -- becomes the typed failure below.  Keep this as a set-based existence
  -- probe so no full reachable temp table is written for every call.
  IF EXISTS (
    SELECT 1
    FROM _mfs_search_scope_nodes sn
    INNER JOIN mfs_search_node n
      ON n.nid = sn.nid AND n.generation = _generation
    INNER JOIN _mfs_search_access a ON a.nid = sn.nid
    LEFT JOIN _mfs_search_blocked blocked ON blocked.nid = sn.nid
    WHERE blocked.nid IS NULL
      AND n.status NOT IN ('hidden', 'deleted')
      AND n.category NOT IN ('hub', 'root')
      AND n.mention_path NOT REGEXP '^__(chat|trash|upload)__($|/)'
      AND (a.permission & 2) = 2
      AND (a.expiry_time = 0 OR a.expiry_time > _now)
      AND (
        _scope_path = ''
        OR LEFT(n.mention_path, CHAR_LENGTH(_scope_path) + 1)
           = CONCAT(_scope_path, '/')
      )
      AND CHAR_LENGTH(IF(
        _scope_path = '', n.mention_path,
        SUBSTRING(n.mention_path, CHAR_LENGTH(_scope_path) + 2)
      )) > 4096
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'MENTION_PATH_TOO_LONG';
  END IF;

  SELECT
    n.nid,
    _hub_id AS hub_id,
    n.parent_id,
    n.name AS filename,
    n.category AS filetype,
    n.extension AS ext,
    n.mimetype,
    a.permission AS capability,
    _area AS area,
    n.isalink,
    IF(
      _scope_path = '', n.mention_path,
      SUBSTRING(n.mention_path, CHAR_LENGTH(_scope_path) + 2)
    ) AS mention_path
  FROM _mfs_search_scope_nodes sn
  INNER JOIN mfs_search_node n
    ON n.nid = sn.nid AND n.generation = _generation
  INNER JOIN _mfs_search_access a ON a.nid = sn.nid
  LEFT JOIN _mfs_search_blocked blocked ON blocked.nid = sn.nid
  WHERE sn.depth > 0
    AND blocked.nid IS NULL
    AND n.status NOT IN ('hidden', 'deleted')
    AND n.category NOT IN ('hub', 'root')
    AND n.mention_path NOT REGEXP '^__(chat|trash|upload)__($|/)'
    AND (a.permission & 2) = 2
    AND (a.expiry_time = 0 OR a.expiry_time > _now)
    AND (
      _scope_path = ''
      OR LEFT(n.mention_path, CHAR_LENGTH(_scope_path) + 1)
         = CONCAT(_scope_path, '/')
    )
    AND (
      INSTR(n.name_fold, _needle) > 0
      OR INSTR(
        IF(
          _scope_path = '', n.mention_path_fold,
          SUBSTRING(n.mention_path_fold, CHAR_LENGTH(_scope_path) + 2)
        ),
        _needle
      ) > 0
    )
  ORDER BY
    CASE
      WHEN n.name_fold = _needle THEN 0
      WHEN LEFT(n.name_fold, CHAR_LENGTH(_needle)) = _needle THEN 1
      WHEN INSTR(n.name_fold, _needle) > 0 THEN 2
      WHEN INSTR(
        IF(
          _scope_path = '', n.mention_path_fold,
          SUBSTRING(n.mention_path_fold, CHAR_LENGTH(_scope_path) + 2)
        ),
        _needle
      ) > 0 THEN 3
      ELSE 4
    END,
    n.name_fold ASC,
    n.mention_path_fold ASC,
    n.nid ASC
  LIMIT _result_limit;

  DROP TEMPORARY TABLE IF EXISTS _mfs_search_blocked;
  DROP TEMPORARY TABLE IF EXISTS _mfs_search_access;
  DROP TEMPORARY TABLE IF EXISTS _mfs_search_public_lineage;
  DROP TEMPORARY TABLE IF EXISTS _mfs_search_principal_lineage;
  DROP TEMPORARY TABLE IF EXISTS _mfs_search_direct_grant;
  DROP TEMPORARY TABLE IF EXISTS _mfs_search_scope_nodes;
END$

DELIMITER ;
