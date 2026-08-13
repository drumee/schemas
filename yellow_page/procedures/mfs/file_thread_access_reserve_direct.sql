DELIMITER $

DROP PROCEDURE IF EXISTS `file_thread_access_reserve_direct`$
CREATE PROCEDURE `file_thread_access_reserve_direct`(
  IN _transition_id VARCHAR(16),
  IN _lineage_id VARCHAR(16),
  IN _actor_id VARCHAR(16),
  IN _hub_id VARCHAR(16),
  IN _file_nid VARCHAR(16),
  IN _thread_id VARCHAR(16)
)
main: BEGIN
  DECLARE _db_name VARCHAR(90) DEFAULT NULL;
  DECLARE _effective_lineage_id VARCHAR(16) DEFAULT NULL;
  DECLARE _current_thread_id VARCHAR(16) DEFAULT NULL;
  DECLARE _current_operation_id VARCHAR(16) DEFAULT NULL;
  DECLARE _current_state VARCHAR(16) DEFAULT NULL;
  DECLARE _revision BIGINT UNSIGNED DEFAULT 0;
  DECLARE _now INT(11) UNSIGNED DEFAULT UNIX_TIMESTAMP();
  DECLARE _changed INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SELECT 1 AS failed, 0 AS reserved, 'DIRECT_RESERVATION_FAILED' AS status;
  END;

  SELECT db_name INTO _db_name FROM entity WHERE id = _hub_id LIMIT 1;
  IF _db_name IS NULL THEN
    SELECT 1 AS failed, 0 AS reserved, 'HUB_NOT_FOUND' AS status;
    LEAVE main;
  END IF;

  START TRANSACTION;

  SET @_direct_media_id = NULL;
  SET @_direct_thread_id = NULL;
  SET @st = CONCAT('SELECT id INTO @_direct_media_id FROM `',
    REPLACE(_db_name, '`', '``'),
    '`.media WHERE id = ? AND status NOT IN (''hidden'',''deleted'') LIMIT 1 FOR UPDATE');
  PREPARE stmt FROM @st;
  EXECUTE stmt USING _file_nid;
  DEALLOCATE PREPARE stmt;

  SET @st = CONCAT('SELECT root_message_id INTO @_direct_thread_id FROM `',
    REPLACE(_db_name, '`', '``'),
    '`.file_thread WHERE file_nid = ? AND root_message_id = ? ',
    'AND status = ''active'' LIMIT 1 FOR UPDATE');
  PREPARE stmt FROM @st;
  EXECUTE stmt USING _file_nid, _thread_id;
  DEALLOCATE PREPARE stmt;

  IF @_direct_media_id IS NULL OR @_direct_thread_id IS NULL THEN
    ROLLBACK;
    SELECT 0 AS failed, 0 AS reserved, 'DIRECT_SOURCE_CHANGED' AS status;
    LEAVE main;
  END IF;

  -- Keyed on the thread, not the file node.
  --
  -- A cross-hub move gives the file a new node id every time it travels, so a
  -- lookup by current_file_nid stops matching the moment the file moves once.
  -- Reserve then found nothing, inserted a second lineage for the same thread,
  -- and left the previous row parked in 'moving' with an operation id no one
  -- would ever clear. Twelve such rows accumulated in a single day of testing,
  -- all pointing at node ids that no longer exist in any database.
  --
  -- The thread id is the stable identity: it survives every move of its file.
  -- Fall back to the file position only when no row carries the thread yet,
  -- which covers a lineage written before this procedure was keyed this way.
  SELECT lineage_id, current_thread_id, current_operation_id, state, access_revision
    INTO _effective_lineage_id, _current_thread_id, _current_operation_id,
      _current_state, _revision
  FROM file_thread_lineage
  WHERE current_hub_id = _hub_id AND current_thread_id = _thread_id
  ORDER BY (current_file_nid = _file_nid) DESC, mtime DESC
  LIMIT 1 FOR UPDATE;

  IF _effective_lineage_id IS NULL THEN
    SELECT lineage_id, current_thread_id, current_operation_id, state, access_revision
      INTO _effective_lineage_id, _current_thread_id, _current_operation_id,
        _current_state, _revision
    FROM file_thread_lineage
    WHERE current_hub_id = _hub_id AND current_file_nid = _file_nid
    LIMIT 1 FOR UPDATE;
  END IF;

  IF _effective_lineage_id IS NULL THEN
    SET _effective_lineage_id = _lineage_id;
    INSERT INTO file_thread_lineage (
      lineage_id, original_hub_id, original_file_nid, original_thread_id,
      current_hub_id, current_file_nid, current_thread_id,
      current_operation_id, last_transition_id, last_transition_reason,
      access_revision, state, created_by, ctime, mtime
    ) VALUES (
      _effective_lineage_id, _hub_id, _file_nid, _thread_id,
      _hub_id, _file_nid, _thread_id,
      NULL, NULL, NULL, 0, 'active', _actor_id, _now, _now
    );
    SET _current_thread_id = _thread_id;
    SET _current_state = 'active';
    SET _revision = 0;
  END IF;

  IF _current_operation_id = _transition_id AND _current_state = 'moving' THEN
    COMMIT;
    SELECT 0 AS failed, 1 AS reserved, 'ALREADY_RESERVED' AS status,
      _effective_lineage_id AS lineage_id, _transition_id AS transition_id,
      _revision AS access_revision;
    LEAVE main;
  END IF;

  IF _current_state <> 'active' OR _current_operation_id IS NOT NULL
     OR _current_thread_id <> _thread_id THEN
    ROLLBACK;
    SELECT 0 AS failed, 0 AS reserved, 'LINEAGE_BUSY' AS status,
      _effective_lineage_id AS lineage_id, _revision AS access_revision;
    LEAVE main;
  END IF;

  -- Re-point the lineage at the node the file is on now. The row was found by
  -- thread, so its current_file_nid may still name the node from a previous
  -- move; matching on it here would fail the CAS for exactly the rows this
  -- lookup was widened to catch.
  UPDATE file_thread_lineage
  SET state = 'moving', current_operation_id = _transition_id,
      current_file_nid = _file_nid, mtime = _now
  WHERE lineage_id = _effective_lineage_id
    AND current_hub_id = _hub_id
    AND current_thread_id = _thread_id
    AND current_operation_id IS NULL
    AND state = 'active';

  SET _changed = ROW_COUNT();
  IF _changed <> 1 THEN
    ROLLBACK;
    SELECT 0 AS failed, 0 AS reserved, 'RESERVATION_CAS_MISMATCH' AS status;
    LEAVE main;
  END IF;

  COMMIT;
  SELECT 0 AS failed, 1 AS reserved, 'RESERVED' AS status,
    _effective_lineage_id AS lineage_id, _transition_id AS transition_id,
    _revision AS access_revision;
END $

DELIMITER ;
