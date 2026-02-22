-- Count all folders for reward hub EA1, OT2, DT2 verification.
-- Returns: private folders (category='folder') + team folders (hub media + folders in hub dbs).
-- Used when reward hub db connection lacks cross-db SELECT on a_*/7_*/f_*.
DELIMITER $

DROP PROCEDURE IF EXISTS `count_user_folders`$
CREATE PROCEDURE `count_user_folders`(
  IN _uid VARCHAR(16),
  IN _mode VARCHAR(16)
)
BEGIN
  DECLARE _user_db VARCHAR(64);
  DECLARE _hub_db VARCHAR(64);
  DECLARE _cnt INT UNSIGNED DEFAULT 0;
  DECLARE _hub_cnt INT UNSIGNED DEFAULT 0;
  DECLARE _private_cnt INT UNSIGNED DEFAULT 0;
  DECLARE _time_cond VARCHAR(256) DEFAULT '';
  DECLARE done INT DEFAULT 0;
  DECLARE cur CURSOR FOR
    SELECT e.db_name FROM entity e
    INNER JOIN hub h ON h.id = e.id
    WHERE h.owner_id = _uid AND e.status = 'active' AND e.db_name IS NOT NULL AND e.db_name != '';
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  IF _mode IS NULL OR _mode = '' THEN
    SET _mode = 'all';
  END IF;

  IF _mode = 'daily' THEN
    SET _time_cond = ' AND GREATEST(COALESCE(upload_time,0), COALESCE(publish_time,0)) >= UNIX_TIMESTAMP(NOW()) - 86400';
  END IF;

  -- 1) Get user db and count private folders (category='folder' OR mimetype='folder')
  SELECT db_name INTO _user_db FROM entity WHERE id = _uid LIMIT 1;
  IF _user_db IS NOT NULL AND _user_db != '' THEN
    SET @sql = CONCAT(
      'SELECT COUNT(*) INTO @private_cnt FROM `', _user_db, '`.media ',
      'WHERE (owner_id = ''', REPLACE(_uid, '''', ''''''), ''' OR owner_id IS NULL) ',
      'AND status = ''active'' AND (category = ''folder'' OR mimetype = ''folder'')',
      _time_cond
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    SET _private_cnt = IFNULL(@private_cnt, 0);
    SET _cnt = _private_cnt;
  END IF;

  -- 2) Count hub media (team folder refs)
  IF _user_db IS NOT NULL AND _user_db != '' THEN
    SET @sql = CONCAT(
      'SELECT COUNT(*) INTO @hub_media_cnt FROM `', _user_db, '`.media ',
      'WHERE (owner_id = ''', REPLACE(_uid, '''', ''''''), ''' OR owner_id IS NULL) ',
      'AND status = ''active'' AND (category = ''hub'' OR mimetype = ''hub'')',
      IF(_mode = 'daily', ' AND GREATEST(COALESCE(upload_time,0), COALESCE(publish_time,0)) >= UNIX_TIMESTAMP(NOW()) - 86400', '')
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    SET _cnt = _cnt + IFNULL(@hub_media_cnt, 0);
  END IF;

  -- 3) Count folders in each hub db (team folders)
  SET done = 0;
  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO _hub_db;
    IF done THEN
      LEAVE read_loop;
    END IF;
    IF _hub_db IS NOT NULL AND _hub_db != '' AND _hub_db != _user_db THEN
      SET @sql = CONCAT(
        'SELECT COUNT(*) INTO @folder_cnt FROM `', _hub_db, '`.media ',
        'WHERE (owner_id = ''', REPLACE(_uid, '''', ''''''), ''' OR owner_id IS NULL) ',
        'AND status = ''active'' AND (category = ''folder'' OR mimetype = ''folder'')',
        _time_cond
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
