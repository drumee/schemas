DELIMITER $

DROP PROCEDURE IF EXISTS `file_thread_access_transition_direct`$
CREATE PROCEDURE `file_thread_access_transition_direct`(
  IN _transition_id VARCHAR(16),
  IN _lineage_id VARCHAR(16),
  IN _actor_id VARCHAR(16),
  IN _hub_id VARCHAR(16),
  IN _file_nid VARCHAR(16),
  IN _thread_id VARCHAR(16),
  IN _target_state VARCHAR(16),
  IN _reason VARCHAR(32)
)
main: BEGIN
  DECLARE _db_name VARCHAR(90) DEFAULT NULL;
  DECLARE _effective_lineage_id VARCHAR(16) DEFAULT NULL;
  DECLARE _current_state VARCHAR(16) DEFAULT NULL;
  DECLARE _current_operation_id VARCHAR(16) DEFAULT NULL;
  DECLARE _revision BIGINT UNSIGNED DEFAULT 0;
  DECLARE _expected_state VARCHAR(16);
  DECLARE _now INT(11) UNSIGNED DEFAULT UNIX_TIMESTAMP();
  DECLARE _changed INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SELECT 1 AS failed, 0 AS transitioned, 'DIRECT_TRANSITION_FAILED' AS status;
  END;

  IF _target_state NOT IN ('active','unavailable')
     OR _reason NOT IN ('direct_trash','direct_restore') THEN
    SELECT 1 AS failed, 0 AS transitioned, 'INVALID_DIRECT_TRANSITION' AS status;
    LEAVE main;
  END IF;

  SELECT db_name INTO _db_name FROM entity WHERE id = _hub_id LIMIT 1;
  IF _db_name IS NULL THEN
    SELECT 1 AS failed, 0 AS transitioned, 'HUB_NOT_FOUND' AS status;
    LEAVE main;
  END IF;

  START TRANSACTION;

  SET @_direct_media_id = NULL;
  SET @_direct_thread_id = NULL;
  SET @st = CONCAT('SELECT id INTO @_direct_media_id FROM `',
    REPLACE(_db_name, '`', '``'), '`.media WHERE id = ? LIMIT 1 FOR UPDATE');
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

  IF @_direct_thread_id IS NULL
     OR (_target_state = 'unavailable' AND @_direct_media_id IS NOT NULL)
     OR (_target_state = 'active' AND @_direct_media_id IS NULL) THEN
    ROLLBACK;
    SELECT 0 AS failed, 0 AS transitioned, 'DURABLE_STATE_MISMATCH' AS status;
    LEAVE main;
  END IF;

  SELECT lineage_id, state, current_operation_id, access_revision
    INTO _effective_lineage_id, _current_state, _current_operation_id, _revision
  FROM file_thread_lineage
  WHERE current_hub_id = _hub_id AND current_file_nid = _file_nid
  LIMIT 1 FOR UPDATE;

  IF _effective_lineage_id IS NULL THEN
    COMMIT;
    SELECT 0 AS failed, 0 AS transitioned,
      IF(_target_state = 'active', 'LINEAGE_NOT_TRACKED', 'RESERVATION_REQUIRED') AS status;
    LEAVE main;
  END IF;

  IF _current_state = _target_state THEN
    COMMIT;
    SELECT 0 AS failed, 0 AS transitioned, 'ALREADY_APPLIED' AS status,
      lineage_id, last_transition_id AS transition_id, access_revision
    FROM file_thread_lineage WHERE lineage_id = _effective_lineage_id;
    LEAVE main;
  END IF;

  IF (_target_state = 'unavailable'
      AND (_current_state <> 'moving' OR _current_operation_id <> _transition_id))
     OR (_target_state = 'active'
      AND (_current_state <> 'unavailable' OR _current_operation_id IS NOT NULL)) THEN
    COMMIT;
    SELECT 0 AS failed, 0 AS transitioned,
      IF(_current_operation_id IS NOT NULL, 'LINEAGE_MOVING', 'DIRECT_STATE_CONFLICT') AS status,
      _effective_lineage_id AS lineage_id, _revision AS access_revision;
    LEAVE main;
  END IF;

  SET _expected_state = IF(_target_state = 'active', 'unavailable', 'moving');
  UPDATE file_thread_lineage
  SET state = _target_state,
      current_operation_id = NULL,
      last_transition_id = _transition_id,
      last_transition_reason = _reason,
      access_revision = access_revision + 1,
      mtime = _now
  WHERE lineage_id = _effective_lineage_id
    AND current_hub_id = _hub_id
    AND current_file_nid = _file_nid
    AND current_thread_id = _thread_id
    AND ((_target_state = 'unavailable' AND current_operation_id = _transition_id)
      OR (_target_state = 'active' AND current_operation_id IS NULL))
    AND state = _expected_state;

  SET _changed = ROW_COUNT();
  COMMIT;

  SELECT 0 AS failed, _changed AS transitioned,
    IF(_changed = 1, 'APPLIED', 'CAS_MISMATCH') AS status,
    lineage_id, last_transition_id AS transition_id, access_revision
  FROM file_thread_lineage WHERE lineage_id = _effective_lineage_id;
END $

DELIMITER ;
