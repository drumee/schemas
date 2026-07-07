DELIMITER $

-- =========================================================
-- channel_export_file_thread_count
-- Count messages in ONE file thread for the 10k export guard.
-- Date bounds arrive as VARCHAR and are NULL-safe: '' / NULL =
-- no filter (the mariadb layer sends '' for a JS null param,
-- which an INT(11) IN-param rejects in strict SQL mode).
-- READ-ONLY: no UPDATE / INSERT.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_export_file_thread_count`$
CREATE PROCEDURE `channel_export_file_thread_count`(
  IN _uid            VARCHAR(16),
  IN _file_thread_id VARCHAR(16),
  IN _date_start     VARCHAR(20),
  IN _date_end       VARCHAR(20)
)
BEGIN
  DECLARE ds BIGINT DEFAULT NULL;
  DECLARE de BIGINT DEFAULT NULL;
  IF _date_start IS NOT NULL AND _date_start <> '' THEN SET ds = CAST(_date_start AS UNSIGNED); END IF;
  IF _date_end   IS NOT NULL AND _date_end   <> '' THEN SET de = CAST(_date_end   AS UNSIGNED); END IF;

  SELECT COUNT(*) AS message_count
  FROM channel c
  WHERE
    c.file_thread_id = _file_thread_id
    AND NOT EXISTS (
      SELECT 1 FROM delete_channel
      WHERE uid = _uid AND ref_sys_id = c.sys_id
    )
    AND (ds IS NULL OR c.ctime >= ds)
    AND (de IS NULL OR c.ctime <= de);
END $

DELIMITER ;
