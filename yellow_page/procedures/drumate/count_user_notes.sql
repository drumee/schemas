-- Count notes for reward hub OT4 verification.
-- Returns: notes (category note/markdown/text) in user db media table.
-- Used when reward hub db connection lacks cross-db SELECT on a_*.
DELIMITER $

DROP PROCEDURE IF EXISTS `count_user_notes`$
CREATE PROCEDURE `count_user_notes`(
  IN _uid VARCHAR(16)
)
BEGIN
  DECLARE _user_db VARCHAR(64);
  DECLARE _cnt INT UNSIGNED DEFAULT 0;

  SELECT db_name INTO _user_db FROM entity WHERE id = _uid LIMIT 1;
  IF _user_db IS NOT NULL AND _user_db != '' THEN
    SET @sql = CONCAT(
      'SELECT COUNT(*) INTO @note_cnt FROM `', _user_db, '`.media ',
      'WHERE (owner_id = ''', REPLACE(_uid, '''', ''''''), ''' OR owner_id IS NULL) ',
      'AND status IN (''active'', ''locked'') ',
      'AND (category = ''note'' OR category = ''markdown'' OR (category = ''text'' AND mimetype IN (''text/markdown'', ''plain/text'')))'
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    SET _cnt = IFNULL(@note_cnt, 0);
  END IF;

  SELECT _cnt AS cnt;
END$

DELIMITER ;
