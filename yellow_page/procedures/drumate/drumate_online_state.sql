DELIMITER $

DROP FUNCTION IF EXISTS `socket_user_conn_nb`$
DROP FUNCTION IF EXISTS `user_online_state`$
DROP FUNCTION IF EXISTS `drumate_online_state`$
DROP PROCEDURE IF EXISTS `drumate_online_state`$
DROP PROCEDURE IF EXISTS `drumate_contacts_state`$
CREATE PROCEDURE `drumate_online_state`(
  IN _uid VARCHAR(80) CHARACTER SET ascii 
)
BEGIN
  DECLARE _state INTEGER DEFAULT 0;
  DECLARE _db_name VARCHAR(64) CHARACTER SET ascii  DEFAULT NULL;
  SET @s = NULL;
  SELECT db_name FROM entity WHERE id=_uid INTO _db_name;
  IF _db_name IS NULL THEN
    SELECT db_name FROM entity WHERE id='ffffffffffffffff' INTO _db_name;
  END IF;
  SELECT online_state(_uid) INTO _state;
  SET @s = CONCAT(
    "SELECT ", 
    quote(_uid), " user_id, ",
    _state , " my_state, ",
    quote(_uid), " my_id, ",
    "yp.online_state(s.uid) his_state, ",
    "s.uid his_id, s.uid, c.firstname, c.lastname, s.id, s.server ",
    "FROM ", _db_name, ".contact c INNER JOIN socket s ON s.uid=c.uid ",
    "WHERE s.state = 'active'"
  );

  PREPARE stmt FROM @s;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
END$

DELIMITER ;