DELIMITER $

-- =========================================================
-- channel_export_messages
-- READ-ONLY clone of channel_list_messages.
-- Differences from the original:
--   1. The mark-seen block (UPDATE channel metadata._seen_ +
--      INSERT read_channel) is entirely ABSENT — export must
--      not alter any read state.
--   2. Date-range filter: NULL/'' bound = no constraint (export
--      full history when client omits dates). Bounds arrive as
--      VARCHAR because the mariadb layer sends '' for a JS null
--      param, which an INT(11) IN-param rejects in strict mode.
--   3. ORDER BY sys_id ASC (export order, oldest first).
--   4. No _sort_by / _order params — always ascending.
--   5. Folder-subtree scope: general-chat messages carry their
--      folder in metadata._scope_nid; only rows whose folder is
--      inside the subtree rooted at _root_nid are returned.
--      Legacy rows (no _scope_nid — the live UI shows them in
--      every folder context) are always included; the service
--      groups them into the export-root section.
--      _root_nid NULL/''/'0' = hub root (whole hub).
--   6. scope_nid exposed as a column so the service can group
--      messages into one section per folder.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_export_messages`$
CREATE PROCEDURE `channel_export_messages`(
  IN _uid        VARCHAR(16),
  IN _root_nid   VARCHAR(16),
  IN _date_start VARCHAR(20),
  IN _date_end   VARCHAR(20),
  IN _page       TINYINT(4)
)
BEGIN
  DECLARE _range  BIGINT;
  DECLARE _offset BIGINT;
  DECLARE _root   VARCHAR(16) DEFAULT NULL;
  DECLARE ds BIGINT DEFAULT NULL;
  DECLARE de BIGINT DEFAULT NULL;
  IF _date_start IS NOT NULL AND _date_start <> '' THEN SET ds = CAST(_date_start AS UNSIGNED); END IF;
  IF _date_end   IS NOT NULL AND _date_end   <> '' THEN SET de = CAST(_date_end   AS UNSIGNED); END IF;
  CALL pageToLimits(_page, _offset, _range);

  IF _root_nid IS NOT NULL AND _root_nid <> '' AND _root_nid <> '0' THEN
    SELECT id INTO _root FROM media WHERE id = _root_nid LIMIT 1;
  END IF;
  IF _root IS NULL THEN
    SELECT id INTO _root FROM media WHERE parent_id = '0' LIMIT 1;
  END IF;

  WITH RECURSIVE subtree AS (
    SELECT m.id FROM media m WHERE m.id = _root
    UNION ALL
    SELECT c.id
    FROM media c
    INNER JOIN subtree s ON c.parent_id = s.id
    WHERE c.mimetype = 'folder' AND c.status = 'active'
  )
  SELECT
    _page AS `page`,
    c.sys_id,
    c.author_id,
    c.message,
    c.message_id,
    c.thread_id,
    c.file_thread_id,
    c.is_forward,
    c.mention_ids,
    c.attachment,
    CASE WHEN LTRIM(RTRIM(c.attachment)) = '' OR c.attachment IS NULL THEN 0 ELSE 1 END AS is_attachment,
    c.status,
    c.ctime,
    c.metadata,
    read_json_object(c.metadata, '_scope_nid')                   AS scope_nid,
    IFNULL(read_json_object(c.metadata, 'message_type'), 'chat') AS message_type,
    COALESCE(d.firstname, du.name, '')                           AS firstname,
    COALESCE(d.lastname, '')                                     AS lastname,
    TRIM(COALESCE(NULLIF(CONCAT_WS(' ', d.firstname, d.lastname), ''), du.name, '')) AS fullname
  FROM (
    SELECT c.sys_id FROM channel c
    WHERE
      NOT EXISTS (
        SELECT 1 FROM delete_channel
        WHERE uid = _uid AND ref_sys_id = c.sys_id
      )
      AND c.file_thread_id IS NULL
      AND (ds IS NULL OR c.ctime >= ds)
      AND (de IS NULL OR c.ctime <= de)
      AND (
        read_json_object(c.metadata, '_scope_nid') = ''
        OR read_json_object(c.metadata, '_scope_nid') IN (SELECT id FROM subtree)
      )
    ORDER BY c.sys_id ASC
    LIMIT _offset, _range
  ) s
  INNER JOIN channel c  ON c.sys_id = s.sys_id
  LEFT  JOIN yp.drumate d  ON c.author_id = d.id
  LEFT  JOIN yp.dmz_user du ON c.author_id = du.id
  ORDER BY c.sys_id ASC;
END $

DELIMITER ;
