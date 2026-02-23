-- Count team folders for reward hub OT3 verification.
-- Returns: hub media (category='hub') in user db + folders in hub dbs.
-- Used when reward hub db connection lacks cross-db SELECT on a_*/7_*/f_*.
DELIMITER $

DROP PROCEDURE IF EXISTS `count_team_folders`$
CREATE PROCEDURE `count_team_folders`(
  IN _uid VARCHAR(16)
)
BEGIN
  DECLARE _user_db VARCHAR(64);
  DECLARE _hub_db VARCHAR(64);
  DECLARE _cnt INT UNSIGNED DEFAULT 0;
  DECLARE _hub_cnt INT UNSIGNED DEFAULT 0;
  DECLARE done INT DEFAULT 0;
  DECLARE cur CURSOR FOR
    SELECT e.db_name FROM entity e
    INNER JOIN hub h ON h.id = e.id
    WHERE h.owner_id = _uid AND e.status = 'active' AND e.db_name IS NOT NULL AND CHAR_LENGTH(TRIM(COALESCE(e.db_name, ''))) > 0;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  -- 1) Get user db and count hub media
  SELECT db_name INTO _user_db FROM entity WHERE id = _uid LIMIT 1;
  IF _user_db IS NOT NULL AND CHAR_LENGTH(TRIM(COALESCE(_user_db, ''))) > 0 THEN
    SET @sql = CONCAT(
      'SELECT COUNT(*) INTO @hub_media_cnt FROM `', _user_db, '`.media ',
      'WHERE (owner_id = ', QUOTE(_uid), ' OR owner_id IS NULL) ',
      'AND status = ', QUOTE('active'), ' AND (category = ', QUOTE('hub'), ' OR mimetype = ', QUOTE('hub'), ')'
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    SET _cnt = IFNULL(@hub_media_cnt, 0);
  END IF;

  -- 2) Count folders in each hub db
  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO _hub_db;
    IF done THEN
      LEAVE read_loop;
    END IF;
    IF _hub_db IS NOT NULL AND CHAR_LENGTH(TRIM(COALESCE(_hub_db, ''))) > 0 AND _hub_db != _user_db THEN
      SET @sql = CONCAT(
        'SELECT COUNT(*) INTO @folder_cnt FROM `', _hub_db, '`.media ',
        'WHERE (owner_id = ', QUOTE(_uid), ' OR owner_id IS NULL) ',
        'AND status = ', QUOTE('active'), ' AND (category = ', QUOTE('folder'), ' OR mimetype = ', QUOTE('folder'), ')'
      );
      PREPARE stmt2 FROM @sql;
      EXECUTE stmt2;
      DEALLOCATE PREPARE stmt2;
      SET _hub_cnt = IFNULL(@folder_cnt, 0);
      SET _cnt = _cnt + _hub_cnt;
    END IF;
  END LOOP;
  CLOSE cur;

  SELECT _cnt AS cnt;
END$

DELIMITER ;
