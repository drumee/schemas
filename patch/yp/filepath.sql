DROP TABLE IF EXISTS `tmp_ck_filepath`
CREATE TABLE `tmp_ck_filepath` (
  `id` varchar(16) NOT NULL,
  `filepath` varchar(1000) NOT NULL
);
BEGIN
  DECLARE _finished INTEGER DEFAULT 0;
  DECLARE _db_name VARCHAR(80) DEFAULT NULL;
  DECLARE _eid VARCHAR(16) DEFAULT NULL;
  DECLARE dbcursor CURSOR FOR SELECT e.id, e.db_name FROM entity e;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 
  OPEN dbcursor;
    STARTLOOP: LOOP
      FETCH dbcursor INTO _eid, _db_name;
      IF _finished = 1 THEN 
        LEAVE STARTLOOP;
      END IF;  

      SET @s = CONCAT(
        "SELECT file_path FROM ", _db_name, ".media", 
        "WHERE parent_id='0' INTO @_filepath");
      IF @s IS NOT NULL THEN 
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
      END IF;
      IF @_filepath REGEXP '^(/__trash__)' THEN
        INSERT INTO  tmp_ck_filepath SELECT _eid, _db_name;
      END IF;
      END LOOP STARTLOOP;
  CLOSE dbcursor;
END;