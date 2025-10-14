DELIMITER $


-- =======================================================================
-- For admin 
-- =======================================================================
DROP PROCEDURE IF EXISTS `list_procs`$
CREATE PROCEDURE `list_procs`(
  IN _dbname VARCHAR(32)
)
BEGIN

  SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_SCHEMA = _dbname
  AND ROUTINE_TYPE = 'PROCEDURE';

END $

-- =========================================================
-- Gets frozen entities
-- =========================================================
DROP PROCEDURE IF EXISTS `get_frozen_entities`$
CREATE PROCEDURE `get_frozen_entities`()
BEGIN
  SELECT id, ident, fs_host, home_dir, db_name, type FROM entity WHERE status = 'frozen' AND UNIX_TIMESTAMP(TIMESTAMPADD(DAY,90, FROM_UNIXTIME(frozen_time))) < UNIX_TIMESTAMP();
END$

-- =========================================================
-- Clean frozen entities
-- =========================================================
DROP PROCEDURE IF EXISTS `clean_frozen_entities`$
CREATE PROCEDURE `clean_frozen_entities`()
BEGIN
  DECLARE _ts INT(11);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION, SQLWARNING
  BEGIN
    ROLLBACK;
    SELECT 1 AS error;
  END;
  SELECT UNIX_TIMESTAMP() INTO _ts;
  CREATE TEMPORARY TABLE frozen_entity SELECT id, ident, fs_host, home_dir, db_name, type FROM entity WHERE status = 'frozen' AND UNIX_TIMESTAMP(TIMESTAMPADD(DAY,90, FROM_UNIXTIME(frozen_time))) < _ts;
  START TRANSACTION;
    DELETE FROM mailserver.users WHERE username in (SELECT ident FROM frozen_entity);
    DELETE FROM vhost WHERE id IN (SELECT id FROM frozen_entity);
    DELETE FROM drumate WHERE id IN (SELECT id FROM frozen_entity);
    DELETE FROM hub WHERE id IN (SELECT id FROM frozen_entity);
    DELETE FROM entity WHERE id IN (SELECT id FROM frozen_entity);
  COMMIT;
  SELECT 0 AS error, id, ident, fs_host, home_dir, db_name, type FROM frozen_entity;
END$

DROP PROCEDURE IF EXISTS `scan_parent_path`$
CREATE PROCEDURE `scan_parent_path`(
)
BEGIN 
  DECLARE _db_name VARCHAR(30);
  DECLARE _id VARCHAR(30);
  DECLARE _finished INTEGER DEFAULT 0;
  DECLARE dbcursor CURSOR FOR select id, db_name from yp.entity where area='pool';
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 
  DROP TABLE IF EXISTS _tmp_fix;
  CREATE TEMPORARY TABLE _tmp_fix AS select id, db_name from yp.entity WHERE 1=2;

  OPEN dbcursor;
    STARTLOOP: LOOP
    FETCH dbcursor INTO _id, _db_name;
    IF _finished = 1 THEN 
      LEAVE STARTLOOP;
    END IF;
    
    IF NOT (_db_name REGEXP "^NO_DB") THEN 
        SET @s = CONCAT(
            "INSERT INTO _tmp_fix SELECT id, ", quote(_db_name), " FROM ", 
            _db_name, 
            ".media WHERE file_path IN('/__trash__/', '/__trash__')");
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
    END LOOP STARTLOOP;
END$
-- =========================================================
-- Clean frozen entities
-- =========================================================
DROP PROCEDURE IF EXISTS `__show`$

DELIMITER ;

-- #####################
