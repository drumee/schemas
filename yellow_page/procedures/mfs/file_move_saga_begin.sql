DELIMITER $

DROP PROCEDURE IF EXISTS `file_move_saga_begin`$
CREATE PROCEDURE `file_move_saga_begin`(
  IN _operation_id VARCHAR(16),
  IN _lineage_id VARCHAR(16),
  IN _actor_id VARCHAR(16),
  IN _source_hub_id VARCHAR(16),
  IN _source_file_nid VARCHAR(16),
  IN _source_parent_nid VARCHAR(16),
  IN _source_thread_id VARCHAR(16),
  IN _destination_hub_id VARCHAR(16),
  IN _destination_parent_nid VARCHAR(16),
  IN _expires_at INT(11) UNSIGNED
)
main: BEGIN
  DECLARE _now INT(11) UNSIGNED DEFAULT UNIX_TIMESTAMP();
  DECLARE _existing_operation_id VARCHAR(16) DEFAULT NULL;
  DECLARE _effective_lineage_id VARCHAR(16) DEFAULT NULL;
  DECLARE _current_thread_id VARCHAR(16) DEFAULT NULL;
  DECLARE _current_operation_id VARCHAR(16) DEFAULT NULL;
  DECLARE _lineage_state VARCHAR(24) DEFAULT NULL;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SELECT 1 AS failed, 'SAGA_BEGIN_FAILED' AS status;
  END;

  START TRANSACTION;

  SELECT operation_id INTO _existing_operation_id
  FROM file_move_saga
  WHERE source_hub_id = _source_hub_id
    AND source_file_nid = _source_file_nid
    AND destination_hub_id = _destination_hub_id
    AND destination_parent_nid = _destination_parent_nid
  ORDER BY ctime DESC LIMIT 1 FOR UPDATE;

  IF _existing_operation_id IS NOT NULL THEN
    UPDATE file_move_saga
    SET retry_count = retry_count + 1, mtime = _now
    WHERE operation_id = _existing_operation_id;
    COMMIT;
    SELECT 0 AS failed, 1 AS replay, s.*
    FROM file_move_saga s WHERE s.operation_id = _existing_operation_id;
    LEAVE main;
  END IF;

  SELECT lineage_id, current_thread_id, current_operation_id, state
    INTO _effective_lineage_id, _current_thread_id, _current_operation_id, _lineage_state
  FROM file_thread_lineage
  WHERE current_hub_id = _source_hub_id AND current_file_nid = _source_file_nid
  LIMIT 1 FOR UPDATE;

  IF _effective_lineage_id IS NULL THEN
    SET _effective_lineage_id = _lineage_id;
    INSERT INTO file_thread_lineage (
      lineage_id, original_hub_id, original_file_nid, original_thread_id,
      current_hub_id, current_file_nid, current_thread_id,
      current_operation_id, last_transition_id, last_transition_reason,
      access_revision, state, created_by, ctime, mtime
    ) VALUES (
      _effective_lineage_id, _source_hub_id, _source_file_nid, _source_thread_id,
      _source_hub_id, _source_file_nid, _source_thread_id,
      NULL, NULL, NULL, 0, 'active', _actor_id, _now, _now
    );
    SET _current_thread_id = _source_thread_id;
    SET _lineage_state = 'active';
  END IF;

  IF _lineage_state <> 'active' OR _current_operation_id IS NOT NULL
     OR _current_thread_id <> _source_thread_id THEN
    ROLLBACK;
    SELECT 1 AS failed, 'LINEAGE_POSITION_CONFLICT' AS status;
    LEAVE main;
  END IF;

  INSERT INTO file_move_saga (
    operation_id, lineage_id, actor_id,
    source_hub_id, source_file_nid, source_parent_nid, source_thread_id,
    destination_hub_id, destination_parent_nid,
    source_access_revision, state, expires_at, ctime, mtime
  )
  SELECT
    _operation_id, _effective_lineage_id, _actor_id,
    _source_hub_id, _source_file_nid, _source_parent_nid, _source_thread_id,
    _destination_hub_id, _destination_parent_nid,
    access_revision, 'copy_pending', _expires_at, _now, _now
  FROM file_thread_lineage WHERE lineage_id = _effective_lineage_id;

  UPDATE file_thread_lineage
  SET state = 'moving', current_operation_id = _operation_id, mtime = _now
  WHERE lineage_id = _effective_lineage_id AND state = 'active';

  COMMIT;
  SELECT 0 AS failed, 0 AS replay, s.*
  FROM file_move_saga s WHERE s.operation_id = _operation_id;
END $

DELIMITER ;
