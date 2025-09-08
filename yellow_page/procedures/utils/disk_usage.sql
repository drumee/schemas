DELIMITER $
-- =========================================================
-- 
-- =========================================================
DROP FUNCTION IF EXISTS `disk_usage`$
CREATE FUNCTION `disk_usage`(
  _uid VARCHAR(16) 
) RETURNS bigint DETERMINISTIC
BEGIN 
  DECLARE _res FLOAT;
  DECLARE _user FLOAT;
  SELECT SUM(du.size) FROM disk_usage du 
    LEFT JOIN(entity e, hub h) ON hub_id=e.id 
    AND h.id = e.id 
    WHERE h.owner_id=_uid INTO _res;
    
  SELECT SUM(du.size) FROM disk_usage du 
    LEFT JOIN drumate d ON hub_id=d.id 
    WHERE d.id=_uid INTO _user;
  
  RETURN _res + _user;
END$


DROP PROCEDURE IF EXISTS `disk_usage`$
CREATE PROCEDURE `disk_usage`(
  IN _uid VARCHAR(16) 
)
BEGIN 
  DECLARE _total BIGINT DEFAULT 0;
  DECLARE _finished BOOLEAN DEFAULT 0;
  DECLARE _db_name VARCHAR(60);
  DECLARE _filesize BIGINT DEFAULT 0;
  DECLARE _category VARCHAR(60);
  DECLARE _res JSON;

  DECLARE dbcursor CURSOR FOR SELECT e.db_name FROM yp.entity e INNER JOIN yp.hub h USING(id) WHERE owner_id=_uid;
  DECLARE dbcursor2 CURSOR FOR SELECT filesize, category FROM _final;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 

  DROP TABLE IF EXISTS _sum;
  CREATE TEMPORARY TABLE _sum(
    filesize BIGINT,
    category VARCHAR(100)
  );
  OPEN dbcursor;
    STARTLOOP: LOOP
      FETCH dbcursor INTO _db_name;
      IF _finished = 1 THEN 
        LEAVE STARTLOOP;
      END IF;  
      IF _db_name IS NOT NULL THEN 
        -- SET @s1=CONCAT("SELECT @hub_usage + IFNULL(sum(filesize), 0) FROM ", _db_name, ".media INTO @hub_usage");
        -- EXECUTE IMMEDIATE @s1;

        -- SET @s2=CONCAT("SELECT @hub_trash + IFNULL(sum(filesize), 0) FROM ", _db_name, ".trash_media INTO @hub_trash");
        -- EXECUTE IMMEDIATE @s2;

        SET @s=CONCAT("INSERT INTO _sum SELECT sum(filesize), 'hub_usage' FROM ", _db_name, ".media");
        PREPARE stm FROM @s;
        EXECUTE stm;
        DEALLOCATE PREPARE stm;

        SET @s=CONCAT("INSERT INTO _sum SELECT sum(filesize), 'hub_trash' FROM ", _db_name, ".trash_media");
        PREPARE stm FROM @s;
        EXECUTE stm;
        DEALLOCATE PREPARE stm;

        SET @s=CONCAT("INSERT INTO _sum SELECT sum(filesize), category FROM ", _db_name, ".media GROUP BY category");
        PREPARE stm FROM @s;
        EXECUTE stm;
        DEALLOCATE PREPARE stm;

        SET @s=CONCAT("INSERT INTO _sum SELECT sum(filesize), category FROM ", _db_name, ".trash_media GROUP BY category");
        PREPARE stm FROM @s;
        EXECUTE stm;
        DEALLOCATE PREPARE stm;
      END IF;
    END LOOP STARTLOOP;
  CLOSE dbcursor;

  SELECT db_name FROM entity WHERE id=_uid INTO _db_name;
  IF _db_name IS NOT NULL THEN 
    SET @s=CONCAT("INSERT INTO _sum SELECT sum(filesize), 'personal_usage' FROM ", _db_name, ".media");
    PREPARE stm FROM @s;
    EXECUTE stm;
    DEALLOCATE PREPARE stm;

    SET @s=CONCAT("INSERT INTO _sum SELECT sum(filesize), 'personal_trash' FROM ", _db_name, ".trash_media");
    PREPARE stm FROM @s;
    EXECUTE stm;
    DEALLOCATE PREPARE stm;

    SET @s=CONCAT("INSERT INTO _sum SELECT sum(filesize), category FROM ", _db_name, ".media GROUP BY category");
    PREPARE stm FROM @s;
    EXECUTE stm;
    DEALLOCATE PREPARE stm;

    SET @s=CONCAT("INSERT INTO _sum SELECT sum(filesize), category FROM ", _db_name, ".trash_media GROUP BY category");
    PREPARE stm FROM @s;
    EXECUTE stm;
    DEALLOCATE PREPARE stm;
  END IF;

  DELETE FROM _sum WHERE filesize IS NULL;
  SET  @_misc_ = NULL;
  SET @_count = 0;
  
  DROP TABLE IF EXISTS _final;
  CREATE TEMPORARY TABLE _final AS SELECT sum(IFNULL(filesize, 0)) filesize, category FROM _sum GROUP BY category;
  DELETE FROM _final WHERE filesize=0;

  SELECT count(*) FROM _final 
    WHERE category NOT IN('hub_usage', 'hub_trash', 'personal_usage', 'personal_trash') INTO @_count;
  IF  @_count > 10 THEN
    DROP TABLE IF EXISTS _top10;
    CREATE TEMPORARY TABLE _top10 AS SELECT * FROM _final 
      WHERE category NOT IN('hub_usage', 'hub_trash', 'personal_usage', 'personal_trash')
      ORDER BY filesize DESC LIMIT 10;
    SELECT sum(filesize) FROM _final WHERE 
      category NOT IN(SELECT category FROM _top10) AND 
      category NOT IN('hub_usage', 'hub_trash', 'personal_usage', 'personal_trash') 
    INTO @_misc_;
    DELETE FROM _final WHERE 
      category NOT IN(SELECT category FROM _top10) AND 
      category NOT IN('hub_usage', 'hub_trash', 'personal_usage', 'personal_trash');
  END IF;

  SELECT JSON_OBJECT() INTO _res;
  SELECT 0 INTO _finished;
  OPEN dbcursor2;
    STARTLOOP: LOOP
      FETCH dbcursor2 INTO _filesize, _category;
      IF _finished = 1 THEN 
        LEAVE STARTLOOP;
      END IF;
      SELECT JSON_SET(_res, CONCAT("$.", _category), _filesize) INTO _res;
    END LOOP STARTLOOP;
  CLOSE dbcursor2;

  SELECT sum(filesize) FROM _sum WHERE category IN('hub_usage', 'hub_trash', 'personal_usage', 'personal_trash')
    INTO _total;
  SELECT JSON_SET(_res, "$.total",_total) INTO _res;

  IF @_misc_ IS NOT NULL THEN
    SELECT JSON_SET(_res, "$._misc_",@_misc_) INTO _res;
  END IF;

  SELECT _res `usage`;
END$

DELIMITER ;


