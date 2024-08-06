DELIMITER $

-- =========================================================
-- 
-- =========================================================

DROP PROCEDURE  IF EXISTS `mfs_unique_filename`$
CREATE PROCEDURE `mfs_unique_filename`(
  _pid VARCHAR(16) CHARACTER SET ascii,
  _file_name VARCHAR(200),
  _ext VARCHAR(20)
)
BEGIN
  DECLARE _r VARCHAR(2000);
  DECLARE _fname VARCHAR(1024);
  DECLARE _base VARCHAR(1024);
  DECLARE _exten VARCHAR(1024);
  
    SELECT _file_name INTO _fname;
    SELECT _fname INTO _base;
    SELECT '' INTO   _exten;

    IF _fname regexp '\\\([0-9]+\\\)$'  THEN 
      SELECT SUBSTRING_INDEX(_fname, '(', 1) INTO _base;
      SELECT  SUBSTRING_INDEX(_fname, ')', -1) INTO _exten;
    END IF;

    WITH RECURSIVE chk as
      (
        SELECT @de:=0 as n ,  _fname fname,
        (SELECT COUNT(1) FROM media WHERE parent_id = _pid 
          AND user_filename = _fname AND extension=IFNULL(_ext, '')
        ) cnt
      UNION ALL 
        SELECT @de:= n+1 n , CONCAT(_base, "(", n+1, ")", _exten) fname ,
        (SELECT COUNT(1) FROM media WHERE parent_id = _pid 
          AND user_filename = CONCAT(_base, "(", n+1, ")", _exten)
          AND extension=IFNULL(_ext, '') 
        ) cnt
        FROM chk c 
        WHERE n<1000 AND cnt >=1
      )
    SELECT fname FROM chk WHERE n =@de  INTO _r ;

  SELECT  _r user_filename;
END$

DELIMITER ;