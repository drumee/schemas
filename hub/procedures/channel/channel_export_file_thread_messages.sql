DELIMITER $

-- =========================================================
-- channel_export_file_thread_messages
-- READ-ONLY clone of channel_file_thread_list_messages.
-- Differences from the original:
--   1. The mark-seen block (UPDATE channel metadata._seen_)
--      is entirely ABSENT — export must not alter read state.
--   2. Date-range filter: NULL/'' bound = no constraint. Bounds
--      arrive as VARCHAR because the mariadb layer sends '' for a
--      JS null param, which an INT(11) IN-param rejects in strict
--      mode.
--   3. ORDER BY ctime ASC (export order, oldest first).
--   4. No _order param — always ascending ctime.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_export_file_thread_messages`$
CREATE PROCEDURE `channel_export_file_thread_messages`(
  IN _uid            VARCHAR(16),
  IN _file_thread_id VARCHAR(16),
  IN _date_start     VARCHAR(20),
  IN _date_end       VARCHAR(20),
  IN _page           TINYINT(4)
)
BEGIN
  DECLARE _range  BIGINT;
  DECLARE _offset BIGINT;
  DECLARE ds BIGINT DEFAULT NULL;
  DECLARE de BIGINT DEFAULT NULL;
  IF _date_start IS NOT NULL AND _date_start <> '' THEN SET ds = CAST(_date_start AS UNSIGNED); END IF;
  IF _date_end   IS NOT NULL AND _date_end   <> '' THEN SET de = CAST(_date_end   AS UNSIGNED); END IF;
  CALL pageToLimits(_page, _offset, _range);

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
    COALESCE(d.firstname, du.name, '')                           AS firstname,
    COALESCE(d.lastname, '')                                     AS lastname,
    COALESCE(CONCAT(d.firstname, ' ', d.lastname), du.name, '') AS fullname,
    IFNULL(read_json_object(c.metadata, 'message_type'), 'chat') AS message_type,
    read_json_object(c.metadata, 'call_status')                  AS call_status
  FROM (
    SELECT sys_id FROM channel c
    WHERE
      c.file_thread_id = _file_thread_id
      AND NOT EXISTS (
        SELECT 1 FROM delete_channel
        WHERE uid = _uid AND ref_sys_id = c.sys_id
      )
      AND (ds IS NULL OR c.ctime >= ds)
      AND (de IS NULL OR c.ctime <= de)
    ORDER BY c.sys_id ASC
    LIMIT _offset, _range
  ) s
  INNER JOIN channel c   ON c.sys_id = s.sys_id
  LEFT  JOIN yp.drumate d   ON c.author_id = d.id
  LEFT  JOIN yp.dmz_user du ON c.author_id = du.id
  ORDER BY c.sys_id ASC;
END $

DELIMITER ;
