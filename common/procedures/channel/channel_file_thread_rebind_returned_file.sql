DELIMITER $

DROP PROCEDURE IF EXISTS `channel_file_thread_rebind_returned_file`$
CREATE PROCEDURE `channel_file_thread_rebind_returned_file`(
  IN _old_file_nid VARCHAR(16),
  IN _returned_file_nid VARCHAR(16),
  IN _expected_thread_id VARCHAR(16)
)
main: BEGIN
  DECLARE _old_thread_id VARCHAR(16) DEFAULT NULL;
  DECLARE _returned_thread_id VARCHAR(16) DEFAULT NULL;
  DECLARE _returned_parent_nid VARCHAR(16) DEFAULT NULL;
  DECLARE _returned_status VARCHAR(20) DEFAULT NULL;
  DECLARE _now INT(11) UNSIGNED DEFAULT UNIX_TIMESTAMP();

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SELECT 1 AS failed, 'REBIND_FAILED' AS status;
  END;

  START TRANSACTION;

  SELECT parent_id, status INTO _returned_parent_nid, _returned_status
  FROM media WHERE id = _returned_file_nid LIMIT 1 FOR UPDATE;

  IF _returned_parent_nid IS NULL OR _returned_status IN ('hidden','deleted') THEN
    ROLLBACK;
    SELECT 1 AS failed, 'RETURNED_NODE_UNAVAILABLE' AS status;
    LEAVE main;
  END IF;

  SELECT root_message_id INTO _old_thread_id
  FROM file_thread WHERE file_nid = _old_file_nid AND status = 'active'
  LIMIT 1 FOR UPDATE;

  SELECT root_message_id INTO _returned_thread_id
  FROM file_thread WHERE file_nid = _returned_file_nid AND status = 'active'
  LIMIT 1 FOR UPDATE;

  IF _old_thread_id IS NOT NULL AND _returned_thread_id IS NOT NULL
     AND _old_thread_id <> _returned_thread_id THEN
    ROLLBACK;
    SELECT 1 AS failed, 'DESTINATION_THREAD_CONFLICT' AS status;
    LEAVE main;
  END IF;

  IF _returned_thread_id IS NULL THEN
    IF _old_thread_id IS NULL OR _old_thread_id <> _expected_thread_id THEN
      ROLLBACK;
      SELECT 1 AS failed, 'THREAD_LINEAGE_MISMATCH' AS status;
      LEAVE main;
    END IF;

    IF EXISTS(SELECT 1 FROM media WHERE id = _old_file_nid) THEN
      ROLLBACK;
      SELECT 1 AS failed, 'OLD_NODE_STILL_AVAILABLE' AS status;
      LEAVE main;
    END IF;

    UPDATE file_thread
    SET file_nid = _returned_file_nid,
        folder_nid = _returned_parent_nid,
        mtime = GREATEST(mtime, _now)
    WHERE file_nid = _old_file_nid AND root_message_id = _old_thread_id;
    SET _returned_thread_id = _old_thread_id;
  ELSEIF _old_thread_id IS NOT NULL AND _old_thread_id = _returned_thread_id THEN
    DELETE FROM file_thread
    WHERE file_nid = _old_file_nid AND root_message_id = _old_thread_id;
  END IF;

  UPDATE channel
  SET metadata = JSON_SET(COALESCE(metadata, JSON_OBJECT()), '$._file_nid', _returned_file_nid)
  WHERE (message_id = _returned_thread_id OR file_thread_id = _returned_thread_id)
    AND (metadata IS NULL OR JSON_VALID(metadata) = 1);

  UPDATE channel
  SET metadata = JSON_SET(COALESCE(metadata, JSON_OBJECT()), '$._scope_nid', _returned_parent_nid)
  WHERE message_id = _returned_thread_id
    AND (metadata IS NULL OR JSON_VALID(metadata) = 1);

  COMMIT;
  SELECT 0 AS failed, _returned_file_nid AS file_nid,
    _returned_parent_nid AS folder_nid,
    _returned_thread_id AS file_thread_id;
END $

DELIMITER ;
