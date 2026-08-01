DELIMITER $

DROP PROCEDURE IF EXISTS `file_thread_access_release_direct`$
CREATE PROCEDURE `file_thread_access_release_direct`(
  IN _transition_id VARCHAR(16),
  IN _hub_id VARCHAR(16),
  IN _file_nid VARCHAR(16),
  IN _thread_id VARCHAR(16)
)
main: BEGIN
  DECLARE _db_name VARCHAR(90) DEFAULT NULL;
  DECLARE _now INT(11) UNSIGNED DEFAULT UNIX_TIMESTAMP();
  DECLARE _changed INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SELECT 1 AS failed, 0 AS released, 'DIRECT_RELEASE_FAILED' AS status;
  END;

  SELECT db_name INTO _db_name FROM entity WHERE id = _hub_id LIMIT 1;
  IF _db_name IS NULL THEN
    SELECT 1 AS failed, 0 AS released, 'HUB_NOT_FOUND' AS status;
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
    SELECT 0 AS failed, 0 AS released, 'DURABLE_TRASH_PRESENT' AS status;
    LEAVE main;
  END IF;

  UPDATE file_thread_lineage
  SET state = 'active', current_operation_id = NULL, mtime = _now
  WHERE current_hub_id = _hub_id
    AND current_file_nid = _file_nid
    AND current_thread_id = _thread_id
    AND current_operation_id = _transition_id
    AND state = 'moving';

  SET _changed = ROW_COUNT();
  COMMIT;

  SELECT 0 AS failed, _changed AS released,
    IF(_changed = 1, 'RELEASED', 'RESERVATION_NOT_FOUND') AS status;
END $

DELIMITER ;
