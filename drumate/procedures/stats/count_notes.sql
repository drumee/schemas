-- Hub procedure: count notes by user (media table category='note' per desk_disk_usage)
-- Deploy to each user database (same as count_media, count_folders)
-- Used by reward-hub OT4 verification
-- desk_disk_usage accepts _category: 'video', 'image', 'note', NULL = all
-- IN _in JSON: { uid }
-- Returns: cnt
DELIMITER $$

DROP PROCEDURE IF EXISTS `count_notes`$$
CREATE PROCEDURE `count_notes`(
  IN _in JSON
)
BEGIN
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;

  SELECT JSON_UNQUOTE(JSON_EXTRACT(_in, "$.uid")) INTO _uid;

  -- If uid not provided, get from current database context
  IF _uid IS NULL OR _uid = '' THEN
    SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;
  END IF;

  -- Notes stored in media table with category='note'
  SELECT COUNT(*) as cnt
  FROM media
  WHERE (owner_id = _uid OR owner_id IS NULL)
    AND status = 'active'
    AND category = 'note'
  LIMIT 1;
END$$

DELIMITER ;
