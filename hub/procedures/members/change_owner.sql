DELIMITER $

DROP PROCEDURE IF EXISTS `change_owner`$
CREATE PROCEDURE `change_owner`(
  IN _uid VARCHAR(16)
)
BEGIN
  DECLARE _db_name VARCHAR(30);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _ts INT(11);
  DECLARE _finished INTEGER DEFAULT 0;

  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT id FROM yp.entity WHERE db_name=DATABASE() INTO _hub_id;

  DROP TABLE IF EXISTS  _mid_tmp;  
  CREATE TEMPORARY TABLE `_mid_tmp` (db_name   VARCHAR(50));
  INSERT INTO _mid_tmp SELECT db_name FROM permission 
    LEFT JOIN yp.entity e ON entity_id=e.id WHERE permission&32>0 AND resource_id='*';

  BEGIN 
    DECLARE dbcursor CURSOR FOR SELECT db_name FROM _mid_tmp;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;
    OPEN dbcursor;
    WHILE NOT _finished DO 
      FETCH dbcursor INTO _db_name;
      SET @s = CONCAT(
        "UPDATE `" ,_db_name,"`.permission SET permission=31, ", 
        "utime = UNIX_TIMESTAMP() WHERE resource_id=", QUOTE(_hub_id));
      -- SELECT @s;
      PREPARE stmt FROM @s;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
    END WHILE;
  END;

  -- Reset old permission
  UPDATE permission SET permission=31, utime = UNIX_TIMESTAMP()
    WHERE permission&32>0 AND resource_id='*';

  -- Set new permission
  REPLACE INTO permission VALUES(NULL, '*', _uid, '', 0, _ts, _ts, 63, 'share');

  SELECT db_name FROM yp.entity WHERE id=_uid INTO _db_name;
  SET @s = CONCAT(
    "UPDATE `" ,_db_name,"`.permission SET permission=63, ", 
    "utime = UNIX_TIMESTAMP() WHERE resource_id=", QUOTE(_hub_id));
  -- SELECT @s;
  PREPARE stmt FROM @s;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  -- Set register new owner
  UPDATE yp.hub SET owner_id=_uid WHERE id=_hub_id;

  SELECT 
    entity_id AS uid, 
    firstname,
    lastname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.email')), '')) AS email,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.avatar')), 'default')) AS avatar,
    permission AS privilege
  FROM permission INNER JOIN (yp.drumate) ON drumate.id=entity_id 
  WHERE entity_id = _uid;

END $
DELIMITER ;
