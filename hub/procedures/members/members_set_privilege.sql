DELIMITER $

DROP PROCEDURE IF EXISTS `members_set_privilege`$
CREATE PROCEDURE `members_set_privilege`(
  IN _privilege INT(4)
)
BEGIN
  DECLARE _db_name VARCHAR(30);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _finished INTEGER DEFAULT 0;


  -- TO DO : PROPAGET CHANGES IN USERS table media
  SELECT id FROM yp.entity WHERE db_name=DATABASE() INTO _hub_id;

  DROP TABLE IF EXISTS  _mid_tmp;  
  CREATE TEMPORARY TABLE `_mid_tmp` (db_name   VARCHAR(50));
  INSERT INTO _mid_tmp SELECT db_name FROM permission 
    LEFT JOIN yp.entity e ON entity_id=e.id WHERE permission < 31;

  BEGIN 
    DECLARE dbcursor CURSOR FOR SELECT db_name FROM _mid_tmp;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;
    OPEN dbcursor;
    WHILE NOT _finished DO 
      FETCH dbcursor INTO _db_name;
      IF _db_name IS NOT NULL THEN 
        SET @s = CONCAT(
          "UPDATE `" ,_db_name,"`.permission SET permission=",_privilege, 
          ", utime = UNIX_TIMESTAMP() WHERE resource_id=", QUOTE(_hub_id));
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        -- SELECT @s;
      END IF;
    END WHILE;
  END;
  UPDATE permission SET permission=_privilege, utime = UNIX_TIMESTAMP()
    WHERE resource_id='*' AND permission < 31; 

  SELECT 
    p.entity_id AS uid,
    d.firstname,
    JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.email')) AS email,permission as privilege,
    d.lastname
  FROM permission p INNER JOIN (yp.drumate d) ON 
    p.entity_id=d.id;

END $
DELIMITER ;
