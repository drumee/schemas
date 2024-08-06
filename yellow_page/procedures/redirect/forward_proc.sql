DELIMITER $

DROP PROCEDURE IF EXISTS `forward_proc`$
CREATE PROCEDURE `forward_proc`(
  IN _id VARCHAR(250),
  IN _fn VARCHAR(250),
  IN _arg MEDIUMTEXT
)
BEGIN
  DECLARE _db VARCHAR(255);
  SELECT CONCAT('`', db_name, '`') FROM entity 
    WHERE vhost=_id or id=_id or ident=_id INTO _db;
  IF _db != '' OR _db IS NOT NULL THEN
    SET @sx = CONCAT("CALL ",_db, ".", _fn, "(", _arg, ")");

    PREPARE stmtx FROM @sx;
    EXECUTE stmtx;
    DEALLOCATE PREPARE stmtx;
  END IF;
END $

DELIMITER ;
