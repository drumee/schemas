DELIMITER $

DROP PROCEDURE IF EXISTS `yp_change_hub_status`$
CREATE PROCEDURE `yp_change_hub_status`(
  IN _user_id   VARBINARY(16),
  IN _key       VARCHAR(255),
  IN _perm      INT(4),
  IN _status    VARCHAR(100)
)
BEGIN
  DECLARE _db_name VARCHAR(20);
  SET @p=0;
  SELECT `db_name` FROM entity WHERE ident=_key OR id=_key INTO _db_name;
  SET @s = CONCAT("SELECT privilege&", _perm, " FROM `", 
    _db_name, "`.`huber` WHERE id='", _user_id, "' INTO @p");
  PREPARE stmt FROM @s;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
  IF @p > 0 THEN
    UPDATE entity e SET status = _status WHERE db_name = _db_name;
  END IF;
  SELECT @p AS valid_user;
  
END $

DELIMITER $