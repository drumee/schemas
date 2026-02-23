-- Hub procedure: count/sum media by user (file size, file count)
-- Deploy to each user database (same as count_chat_message)
-- Used by reward-hub DT3/DT4/DT5, PT1/PT2, EA1 verification
-- IN _in JSON: { uid, mode }
--   mode: 'daily'   -> SUM(filesize) last 24h, returns total_size
--   mode: 'lifetime'-> SUM(filesize) all time, returns total_size
--   mode: 'file_count' -> COUNT(*) files with filesize>0, returns cnt
DELIMITER $$

DROP PROCEDURE IF EXISTS `count_media`$$
CREATE PROCEDURE `count_media`(
  IN _in JSON
)
BEGIN
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _mode VARCHAR(16) CHARACTER SET ascii;

  SELECT JSON_UNQUOTE(JSON_EXTRACT(_in, "$.uid")) INTO _uid;
  SELECT JSON_UNQUOTE(JSON_EXTRACT(_in, "$.mode")) INTO _mode;

  -- If uid not provided, get from current database context
  IF _uid IS NULL OR CHAR_LENGTH(TRIM(COALESCE(_uid, ''))) = 0 THEN
    SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;
  END IF;

  -- mode: daily = SUM(filesize) last 24h
  IF _mode = 'daily' THEN
    SELECT COALESCE(SUM(filesize), 0) as total_size
    FROM media
    WHERE (owner_id = _uid OR owner_id IS NULL) AND status = 'active'
      AND upload_time >= UNIX_TIMESTAMP(NOW()) - 86400
    LIMIT 1;
  -- mode: lifetime = SUM(filesize) all time
  ELSEIF _mode = 'lifetime' THEN
    SELECT COALESCE(SUM(filesize), 0) as total_size
    FROM media
    WHERE (owner_id = _uid OR owner_id IS NULL) AND status = 'active'
    LIMIT 1;
  -- mode: file_count = COUNT(*) files with filesize > 0
  ELSE
    SELECT COUNT(*) as cnt
    FROM media
    WHERE (owner_id = _uid OR owner_id IS NULL) AND status = 'active' AND filesize > 0
    LIMIT 1;
  END IF;
END$$

DELIMITER ;
