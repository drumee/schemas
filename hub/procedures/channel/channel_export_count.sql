DELIMITER $

-- =========================================================
-- channel_export_count
-- Fast COUNT of hub team-chat messages (file_thread_id IS NULL)
-- for the given uid and optional date range. Used by the
-- 10k guard in channel.export before gathering begins.
-- Date bounds arrive as VARCHAR: the mariadb layer converts a
-- JS null param to '' (empty string), which an INT(11) IN-param
-- rejects under strict SQL mode. Accept text, normalise '' / NULL
-- to a NULL bound (no filter) and CAST numeric strings to epoch.
-- READ-ONLY: no UPDATE / INSERT.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_export_count`$
CREATE PROCEDURE `channel_export_count`(
  IN _uid        VARCHAR(16),
  IN _date_start VARCHAR(20),
  IN _date_end   VARCHAR(20)
)
BEGIN
  DECLARE ds BIGINT DEFAULT NULL;
  DECLARE de BIGINT DEFAULT NULL;
  IF _date_start IS NOT NULL AND _date_start <> '' THEN SET ds = CAST(_date_start AS UNSIGNED); END IF;
  IF _date_end   IS NOT NULL AND _date_end   <> '' THEN SET de = CAST(_date_end   AS UNSIGNED); END IF;

  SELECT COUNT(*) AS message_count
  FROM channel c
  WHERE
    c.file_thread_id IS NULL
    AND NOT EXISTS (
      SELECT 1 FROM delete_channel
      WHERE uid = _uid AND ref_sys_id = c.sys_id
    )
    AND (ds IS NULL OR c.ctime >= ds)
    AND (de IS NULL OR c.ctime <= de);
END $

DELIMITER ;
