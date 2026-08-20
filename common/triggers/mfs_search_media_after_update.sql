DELIMITER $

-- Parent/name/status/category/isalink are authoritative in media.  Any
-- change to one of those fields (or to the display metadata copied by the
-- projection) refreshes the changed subtree before the source UPDATE commits.
DROP TRIGGER IF EXISTS `mfs_search_media_after_update`$
CREATE TRIGGER `mfs_search_media_after_update`
AFTER UPDATE ON `media`
FOR EACH ROW
BEGIN
  DECLARE _state VARCHAR(16) DEFAULT NULL;
  DECLARE _schema_version BIGINT UNSIGNED DEFAULT 0;
  DECLARE _projection_version BIGINT UNSIGNED DEFAULT 0;
  DECLARE _generation BIGINT UNSIGNED DEFAULT 0;
  DECLARE _mutation_high_water BIGINT UNSIGNED DEFAULT 0;
  DECLARE _reconciled_high_water BIGINT UNSIGNED DEFAULT 0;
  DECLARE _ready TINYINT UNSIGNED DEFAULT 0;
  DECLARE _recovering TINYINT UNSIGNED DEFAULT 0;
  DECLARE _can_sync TINYINT UNSIGNED DEFAULT 0;
  DECLARE _projection_complete TINYINT UNSIGNED DEFAULT 0;
  DECLARE _parent_exists TINYINT UNSIGNED DEFAULT 1;
  DECLARE _needs_sync TINYINT UNSIGNED DEFAULT 0;
  DECLARE _next_high_water BIGINT UNSIGNED DEFAULT 0;
  DECLARE _media_count BIGINT UNSIGNED DEFAULT 0;
  DECLARE _projection_count BIGINT UNSIGNED DEFAULT 0;

  INSERT INTO mfs_search_state (
    state_id, state, schema_version, projection_version, generation,
    mutation_high_water, reconciled_high_water, row_count, updated_at
  ) VALUES (1, 'BUILDING', 1, 1, 0, 0, 0, 0, UNIX_TIMESTAMP())
  ON DUPLICATE KEY UPDATE state_id = VALUES(state_id);

  SELECT state, schema_version, projection_version, generation,
         mutation_high_water, reconciled_high_water
    INTO _state, _schema_version, _projection_version, _generation,
         _mutation_high_water, _reconciled_high_water
    FROM mfs_search_state
    WHERE state_id = 1
    FOR UPDATE;
  SET _ready = IF(
    _state = 'READY' AND _schema_version = 1 AND _projection_version = 1
      AND _generation > 0
      AND _mutation_high_water = _reconciled_high_water,
    1, 0
  );
  SET _recovering = IF(
    _state = 'BUILDING' AND _schema_version = 1 AND _projection_version = 1
      AND _generation > 0
      AND _mutation_high_water > _reconciled_high_water,
    1, 0
  );
  SET _can_sync = IF(_ready = 1 OR _recovering = 1, 1, 0);

  SET _needs_sync = IF(NOT (
    BINARY OLD.id <=> BINARY NEW.id
    AND BINARY OLD.parent_id <=> BINARY NEW.parent_id
    AND BINARY OLD.user_filename <=> BINARY NEW.user_filename
    AND BINARY OLD.extension <=> BINARY NEW.extension
    AND BINARY OLD.mimetype <=> BINARY NEW.mimetype
    AND BINARY OLD.category <=> BINARY NEW.category
    AND BINARY OLD.status <=> BINARY NEW.status
    AND OLD.isalink <=> NEW.isalink
    -- file_path/parent_path are storage metadata; mention paths derive from
    -- current parent_id/name lineage and bulk helpers must not cause a
    -- subtree rebuild for every path-only row update.
  ), 1, 0);

  IF _can_sync = 1 AND _needs_sync = 1
     AND (NEW.parent_id IS NULL OR NEW.parent_id <> '0') THEN
    SELECT COUNT(*) INTO _parent_exists FROM media WHERE id = NEW.parent_id;
    IF _parent_exists = 0 THEN
      SET _can_sync = 0;
      SET _ready = 0;
      UPDATE mfs_search_state
      SET state = 'BUILDING', updated_at = UNIX_TIMESTAMP()
      WHERE state_id = 1;
    END IF;
  END IF;

  IF _can_sync = 1 AND _needs_sync = 1 THEN
    -- A metadata-only update does not alter the searchable projection.  It
    -- still advances the source high-water marker, while parent/name and
    -- visibility changes rebuild the affected subtree.
    IF NOT (BINARY OLD.id <=> BINARY NEW.id) THEN
      CALL mfs_search_projection_sync_core(OLD.id);
    END IF;
    CALL mfs_search_projection_sync_core(NEW.id);
  ELSEIF _can_sync = 1 THEN
    -- Keep non-lineage metadata current without rebuilding a whole subtree.
    UPDATE mfs_search_node
    SET file_path = NEW.file_path,
        source_mtime = IFNULL(NEW.publish_time, 0)
    WHERE nid = NEW.id AND generation = _generation;
  END IF;

  SET _next_high_water = _mutation_high_water + 1;
  IF _recovering = 1 AND _can_sync = 1 THEN
    SELECT COUNT(*) INTO _media_count FROM media;
    SELECT COUNT(*) INTO _projection_count
    FROM mfs_search_node WHERE generation = _generation;
    SET _projection_complete = IF(
      _media_count = _projection_count
      AND NOT EXISTS (
        SELECT 1
        FROM media m
        LEFT JOIN mfs_search_node n
          ON n.nid = CONVERT(m.id USING ascii)
         AND n.generation = _generation
        WHERE n.nid IS NULL
           OR NOT (
             BINARY n.parent_id <=> BINARY m.parent_id
             AND BINARY n.name <=> BINARY m.user_filename
             AND BINARY n.extension <=> BINARY m.extension
             AND BINARY n.mimetype <=> BINARY m.mimetype
             AND BINARY n.category <=> BINARY m.category
             AND BINARY n.status <=> BINARY m.status
             AND n.isalink <=> m.isalink
           )
      )
      AND NOT EXISTS (
        SELECT 1
        FROM mfs_search_node n
        LEFT JOIN media m ON m.id = n.nid
        WHERE n.generation <> _generation OR m.id IS NULL
      )
      AND NOT EXISTS (
        SELECT 1
        FROM mfs_search_node n
        LEFT JOIN mfs_search_closure self_link
          ON self_link.ancestor_nid = n.nid
         AND self_link.descendant_nid = n.nid
         AND self_link.depth = 0
         AND self_link.generation = _generation
        LEFT JOIN media parent
          ON parent.id = n.parent_id
        LEFT JOIN mfs_search_closure parent_link
          ON parent_link.ancestor_nid = n.parent_id
         AND parent_link.descendant_nid = n.nid
         AND parent_link.depth = 1
         AND parent_link.generation = _generation
        WHERE n.generation = _generation
          AND (
            self_link.ancestor_nid IS NULL
            OR (
              n.parent_id IS NOT NULL AND n.parent_id <> '0'
              AND (parent.id IS NULL OR parent_link.ancestor_nid IS NULL)
            )
          )
      ),
      1, 0
    );
  END IF;
  UPDATE mfs_search_state
  SET state = IF(_projection_complete = 1, 'READY', state),
      mutation_high_water = _next_high_water,
      reconciled_high_water = IF(
        _ready = 1 OR _projection_complete = 1,
        _next_high_water, reconciled_high_water
      ),
      row_count = IF(_projection_complete = 1, _projection_count, row_count),
      finished_at = IF(_projection_complete = 1, UNIX_TIMESTAMP(), finished_at),
      last_error_code = IF(_projection_complete = 1, NULL, last_error_code),
      last_error_message = IF(_projection_complete = 1, NULL, last_error_message),
      updated_at = UNIX_TIMESTAMP()
  WHERE state_id = 1;
END$

DELIMITER ;
