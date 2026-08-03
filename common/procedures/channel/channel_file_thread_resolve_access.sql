DELIMITER $

-- =========================================================
-- channel_file_thread_resolve_access
-- Canonically resolve a file-thread scope from any combination of file nid,
-- root thread id, and message id. This routine verifies selector agreement and
-- live media state; the service must additionally require mfs_access_node for
-- the caller before reading, mutating, enriching, or broadcasting the scope.
--
-- resolution_status:
--   OK                canonical file exists in live media and is active
--   GENERAL           message exists but is not a file-thread row/root card
--   SELECTOR_CONFLICT supplied selectors identify different scopes
--   NOT_FOUND         supplied message/thread selector does not exist
--   SCOPE_GONE        thread identity remains but its file/thread is not live
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_file_thread_resolve_access`$
CREATE PROCEDURE `channel_file_thread_resolve_access`(
  IN _uid VARCHAR(16),
  IN _file_nid VARCHAR(16),
  IN _file_thread_id VARCHAR(16),
  IN _message_id VARCHAR(16)
)
BEGIN
  DECLARE _message_found INT DEFAULT 0;
  DECLARE _message_thread_id VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _message_file_nid VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _thread_found INT DEFAULT 0;
  DECLARE _thread_file_nid VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _thread_status VARCHAR(16) DEFAULT NULL;
  DECLARE _file_thread_found INT DEFAULT 0;
  DECLARE _file_thread_root VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _file_thread_status VARCHAR(16) DEFAULT NULL;
  DECLARE _resolved_thread_id VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _resolved_file_nid VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _resolved_thread_status VARCHAR(16) DEFAULT NULL;
  DECLARE _media_found INT DEFAULT 0;
  DECLARE _media_status VARCHAR(20) DEFAULT NULL;
  DECLARE _selector_conflict INT DEFAULT 0;
  DECLARE _is_file_thread INT DEFAULT 0;

  IF _message_id IS NOT NULL AND _message_id <> '' THEN
    SELECT
      COUNT(c.sys_id),
      MAX(COALESCE(c.file_thread_id, root_ft.root_message_id))
    INTO _message_found, _message_thread_id
    FROM channel c
    LEFT JOIN file_thread root_ft ON root_ft.root_message_id = c.message_id
    WHERE c.message_id = _message_id;

    IF _message_thread_id IS NOT NULL THEN
      SELECT MAX(ft.file_nid)
      INTO _message_file_nid
      FROM file_thread ft
      WHERE ft.root_message_id = _message_thread_id;
    END IF;
  END IF;

  IF _file_thread_id IS NOT NULL AND _file_thread_id <> '' THEN
    SELECT COUNT(*), MAX(file_nid), MAX(status)
    INTO _thread_found, _thread_file_nid, _thread_status
    FROM file_thread
    WHERE root_message_id = _file_thread_id;
  END IF;

  IF _file_nid IS NOT NULL AND _file_nid <> '' THEN
    SELECT COUNT(*), MAX(root_message_id), MAX(status)
    INTO _file_thread_found, _file_thread_root, _file_thread_status
    FROM file_thread
    WHERE file_nid = _file_nid;
  END IF;

  SET _resolved_thread_id = COALESCE(
    _message_thread_id,
    IF(_thread_found > 0, _file_thread_id, NULL),
    _file_thread_root
  );
  SET _resolved_file_nid = COALESCE(
    _message_file_nid,
    _thread_file_nid,
    _file_nid
  );
  SET _resolved_thread_status = COALESCE(
    IF(_message_thread_id IS NOT NULL,
      (SELECT MAX(status) FROM file_thread WHERE root_message_id = _message_thread_id),
      NULL),
    _thread_status,
    _file_thread_status
  );

  SET _is_file_thread = IF(
    (_file_nid IS NOT NULL AND _file_nid <> '')
    OR (_file_thread_id IS NOT NULL AND _file_thread_id <> '')
    OR _message_thread_id IS NOT NULL,
    1,
    0
  );

  IF _file_nid IS NOT NULL AND _file_nid <> ''
    AND _resolved_file_nid IS NOT NULL
    AND _resolved_file_nid <> _file_nid THEN
    SET _selector_conflict = 1;
  END IF;
  IF _file_thread_id IS NOT NULL AND _file_thread_id <> ''
    AND _resolved_thread_id IS NOT NULL
    AND _resolved_thread_id <> _file_thread_id THEN
    SET _selector_conflict = 1;
  END IF;
  IF _message_id IS NOT NULL AND _message_id <> ''
    AND _message_found > 0
    AND (_file_nid IS NOT NULL AND _file_nid <> ''
      OR _file_thread_id IS NOT NULL AND _file_thread_id <> '')
    AND _message_thread_id IS NULL THEN
    SET _selector_conflict = 1;
  END IF;

  IF _resolved_file_nid IS NOT NULL THEN
    SELECT COUNT(*), MAX(status)
    INTO _media_found, _media_status
    FROM media
    WHERE id = _resolved_file_nid;
  END IF;

  SELECT
    CASE
      WHEN _selector_conflict = 1 THEN 'SELECTOR_CONFLICT'
      WHEN _message_id IS NOT NULL AND _message_id <> '' AND _message_found = 0 THEN 'NOT_FOUND'
      WHEN _file_thread_id IS NOT NULL AND _file_thread_id <> '' AND _thread_found = 0 THEN 'NOT_FOUND'
      WHEN _is_file_thread = 0 THEN 'GENERAL'
      WHEN _resolved_file_nid IS NULL
        OR _media_found = 0
        OR _media_status <> 'active'
        OR (_resolved_thread_id IS NOT NULL AND _resolved_thread_status <> 'active')
        THEN 'SCOPE_GONE'
      ELSE 'OK'
    END AS resolution_status,
    _selector_conflict AS selector_conflict,
    _is_file_thread AS is_file_thread,
    _message_found AS message_found,
    _resolved_thread_id AS file_thread_id,
    _resolved_file_nid AS file_nid,
    _resolved_thread_status AS file_thread_status,
    _media_status AS media_status;
END $

DELIMITER ;
