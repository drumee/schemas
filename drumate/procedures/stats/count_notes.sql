-- Hub procedure: count notes by user (media table)
-- Deploy to each user database (same as count_media, count_folders)
-- Used by reward-hub OT4 verification
-- Notes: note/markdown/text (text mimetypes) or document with text/* or md/txt extension
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
  IF _uid IS NULL OR CHAR_LENGTH(TRIM(COALESCE(_uid, ''))) = 0 THEN
    SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;
  END IF;

  SELECT COUNT(*) as cnt
  FROM media
  WHERE owner_id = _uid
    AND status IN ('active', 'locked')
    AND (
      category IN ('note', 'markdown')
      OR (category = 'text' AND LOWER(TRIM(mimetype)) IN ('text/markdown', 'text/plain', 'plain/text'))
      OR (
        category = 'document'
        AND (
          LOWER(TRIM(mimetype)) LIKE 'text/%'
          OR LOWER(TRIM(mimetype)) IN ('text/markdown', 'text/plain')
          OR LOWER(TRIM(extension)) IN ('md', 'markdown', 'txt', 'mkd')
        )
      )
    )
  LIMIT 1;
END$$

DELIMITER ;
