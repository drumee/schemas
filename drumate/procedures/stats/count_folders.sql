-- Hub procedure: count folders by user (Drumee stores folders in media table with category='folder')
-- Deploy to each user database (same as count_media, count_chat_message)
-- Used by reward-hub OT2, OT3, DT2, EA1 verification
-- IN _in JSON: { uid, mode }
--   mode: 'all'     -> COUNT(*) folders, returns cnt
--   mode: 'daily'   -> COUNT(*) folders created in last 24h, returns cnt
DELIMITER $$

DROP PROCEDURE IF EXISTS `count_folders`$$
CREATE PROCEDURE `count_folders`(
  IN _in JSON
)
BEGIN
  DECLARE _uid VARCHAR(64) CHARACTER SET ascii;
  DECLARE _mode VARCHAR(16) CHARACTER SET ascii;

  SELECT JSON_UNQUOTE(JSON_EXTRACT(_in, "$.uid")) INTO _uid;
  SELECT JSON_UNQUOTE(JSON_EXTRACT(_in, "$.mode")) INTO _mode;

  -- If uid not provided, get from current database context
  IF _uid IS NULL OR CHAR_LENGTH(TRIM(COALESCE(_uid, ''))) = 0 THEN
    SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;
  END IF;

  -- mode: daily = folders created in last 24h (upload_time is unix timestamp)
  IF _mode = 'daily' THEN
    SELECT COUNT(*) as cnt
    FROM media
    WHERE (owner_id = _uid OR owner_id IS NULL) AND status = 'active'
      AND (category = 'folder' OR mimetype = 'folder')
      AND upload_time >= UNIX_TIMESTAMP(NOW()) - 86400
    LIMIT 1;
  -- mode: all = total folder count
  ELSE
    SELECT COUNT(*) as cnt
    FROM media
    WHERE (owner_id = _uid OR owner_id IS NULL) AND status = 'active'
      AND (category = 'folder' OR mimetype = 'folder')
    LIMIT 1;
  END IF;
END$$

DELIMITER ;
