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
  SELECT COALESCE(online_state(_uid), 0) INTO _state;

  -- _db_name stays NULL whenever _uid has no entity row AND the
  -- 'ffffffffffffffff' fallback row is absent -- which is the normal state of
  -- the yellow page: that id is the anonymous/system sentinel the runtime
  -- passes for public-page requests, and it has never existed as an entity.
  -- CONCAT() returns NULL if ANY argument is NULL, so a NULL _db_name made @s
  -- NULL and `PREPARE stmt FROM @s` raised ER_PARSE_ERROR (1064) "... near
  -- 'NULL' at line 1". The caller (push/broadcastStatus, yp/broadcastStatus,
  -- entity/pushUserOnlineStatus) only iterates the rows, so a contact list
  -- that cannot be resolved is a no-op -- return the empty set with the same
  -- column shape instead of failing the request.
  IF _db_name IS NULL THEN
    SELECT
      _uid  AS user_id,
      _state AS my_state,
      _uid  AS my_id,
      0     AS his_state,
      NULL  AS his_id,
      NULL  AS uid,
      NULL  AS firstname,
      NULL  AS lastname,
      NULL  AS id,
      NULL  AS server
    FROM DUAL WHERE FALSE;
  ELSE
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
  END IF;
END$

DELIMITER ;
