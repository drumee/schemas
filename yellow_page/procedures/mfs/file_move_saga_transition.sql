DELIMITER $

DROP PROCEDURE IF EXISTS `file_move_saga_transition`$
CREATE PROCEDURE `file_move_saga_transition`(
  IN _args JSON
)
main: BEGIN
  DECLARE _operation_id VARCHAR(16);
  DECLARE _actor_id VARCHAR(16);
  DECLARE _expected_state VARCHAR(32);
  DECLARE _next_state VARCHAR(32);
  DECLARE _destination_file_nid VARCHAR(16);
  DECLARE _destination_thread_id VARCHAR(16);
  DECLARE _compensation_file_nid VARCHAR(16);
  DECLARE _compensation_thread_id VARCHAR(16);
  DECLARE _failure_code VARCHAR(64);
  DECLARE _lineage_id VARCHAR(16);
  DECLARE _source_hub_id VARCHAR(16);
  DECLARE _source_file_nid VARCHAR(16);
  DECLARE _source_thread_id VARCHAR(16);
  DECLARE _destination_hub_id VARCHAR(16);
  DECLARE _source_revision BIGINT UNSIGNED;
  DECLARE _now INT(11) UNSIGNED DEFAULT UNIX_TIMESTAMP();
  DECLARE _changed INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SELECT 1 AS failed, 'SAGA_TRANSITION_FAILED' AS status;
  END;

  SET _operation_id = JSON_VALUE(_args, '$.operation_id');
  SET _actor_id = JSON_VALUE(_args, '$.actor_id');
  SET _expected_state = JSON_VALUE(_args, '$.expected_state');
  SET _next_state = JSON_VALUE(_args, '$.next_state');
  SET _destination_file_nid = JSON_VALUE(_args, '$.destination_file_nid');
  SET _destination_thread_id = JSON_VALUE(_args, '$.destination_thread_id');
  SET _compensation_file_nid = JSON_VALUE(_args, '$.compensation_file_nid');
  SET _compensation_thread_id = JSON_VALUE(_args, '$.compensation_thread_id');
  SET _failure_code = JSON_VALUE(_args, '$.failure_code');

  START TRANSACTION;

  SELECT lineage_id, source_hub_id, source_file_nid, source_thread_id,
    destination_hub_id, source_access_revision
  INTO _lineage_id, _source_hub_id, _source_file_nid, _source_thread_id,
    _destination_hub_id, _source_revision
  FROM file_move_saga
  WHERE operation_id = _operation_id AND actor_id = _actor_id
  LIMIT 1 FOR UPDATE;

  IF _lineage_id IS NULL THEN
    ROLLBACK;
    SELECT 1 AS failed, 'OPERATION_NOT_FOUND' AS status;
    LEAVE main;
  END IF;

  IF NOT (
    (_expected_state = 'copy_pending' AND _next_state IN ('copy_verified','failed','expired','compensation_failed')) OR
    (_expected_state = 'copy_verified' AND _next_state IN ('source_removed','compensating','failed','expired','compensation_failed')) OR
    (_expected_state = 'source_removed' AND _next_state IN ('committed','compensating','compensation_failed')) OR
    (_expected_state = 'compensating' AND _next_state IN ('compensated','compensation_failed'))
  ) THEN
    ROLLBACK;
    SELECT 1 AS failed, 'INVALID_SAGA_TRANSITION' AS status;
    LEAVE main;
  END IF;

  UPDATE file_move_saga
  SET state = _next_state,
      destination_file_nid = COALESCE(_destination_file_nid, destination_file_nid),
      destination_thread_id = COALESCE(_destination_thread_id, destination_thread_id),
      compensation_file_nid = COALESCE(_compensation_file_nid, compensation_file_nid),
      compensation_thread_id = COALESCE(_compensation_thread_id, compensation_thread_id),
      access_revision = IF(_next_state IN ('committed','compensated'),
        _source_revision + 1, access_revision),
      failure_code = COALESCE(_failure_code, failure_code),
      committed_at = IF(_next_state = 'committed', _now, committed_at),
      mtime = _now
  WHERE operation_id = _operation_id AND actor_id = _actor_id AND state = _expected_state;

  SET _changed = ROW_COUNT();
  IF _changed <> 1 THEN
    ROLLBACK;
    SELECT 1 AS failed, 'SAGA_CAS_MISMATCH' AS status;
    LEAVE main;
  END IF;

  IF _next_state = 'source_removed' THEN
    UPDATE file_thread_lineage
    SET state = 'unavailable', mtime = _now
    WHERE lineage_id = _lineage_id AND current_operation_id = _operation_id;
  ELSEIF _next_state = 'committed' THEN
    UPDATE file_thread_lineage
    SET current_hub_id = _destination_hub_id,
        current_file_nid = _destination_file_nid,
        current_thread_id = _destination_thread_id,
        current_operation_id = NULL,
        last_transition_id = _operation_id,
        last_transition_reason = 'cross_hub_move',
        access_revision = _source_revision + 1,
        state = 'active', mtime = _now
    WHERE lineage_id = _lineage_id AND current_operation_id = _operation_id;
  ELSEIF _next_state = 'compensated' THEN
    UPDATE file_thread_lineage
    SET current_hub_id = _source_hub_id,
        current_file_nid = _compensation_file_nid,
        current_thread_id = _compensation_thread_id,
        current_operation_id = NULL,
        last_transition_id = _operation_id,
        last_transition_reason = 'cross_hub_move_compensated',
        access_revision = _source_revision + 1,
        state = 'active', mtime = _now
    WHERE lineage_id = _lineage_id AND current_operation_id = _operation_id;
  ELSEIF _next_state IN ('failed','expired') THEN
    UPDATE file_thread_lineage
    SET current_operation_id = NULL, state = 'active', mtime = _now
    WHERE lineage_id = _lineage_id AND current_operation_id = _operation_id;
  ELSEIF _next_state = 'compensation_failed' THEN
    UPDATE file_thread_lineage
    SET state = 'failed', mtime = _now
    WHERE lineage_id = _lineage_id AND current_operation_id = _operation_id;
  END IF;

  COMMIT;
  SELECT 0 AS failed, s.*
  FROM file_move_saga s WHERE s.operation_id = _operation_id;
END $

DELIMITER ;
