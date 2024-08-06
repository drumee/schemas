DELIMITER $

DROP PROCEDURE IF EXISTS `cast_user`$
CREATE PROCEDURE `cast_user`(
 IN _admin VARCHAR(90),
 IN _user   VARCHAR(90)
)
BEGIN
  DECLARE _admin_id VARCHAR(16);
  DECLARE _user_id VARCHAR(16);
  SELECT id  FROM drumate  WHERE id=_admin OR
    username=_admin AND remit&2 INTO _admin_id;
  SELECT id FROM  drumate WHERE id=_user OR
    username=_user INTO _user_id;
  SELECT _admin_id admin, _user_id user;
  IF _admin_id IS NULL OR _user_id IS NULL THEN
    SELECT null id;
  ELSE
    SELECT * FROM cookie WHERE uid=_admin_id;
    UPDATE cookie SET uid=_user_id,mimicker=_admin_id WHERE uid=_admin_id;
  END IF;
END $


DELIMITER ;