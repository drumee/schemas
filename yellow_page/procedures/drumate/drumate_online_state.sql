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
  DECLARE _domain_id INTEGER DEFAULT 0;
  SET @s = NULL;
  SELECT db_name FROM entity WHERE id=_uid INTO _db_name;
  IF _db_name IS NULL THEN
    SELECT db_name FROM entity WHERE id='ffffffffffffffff' INTO _db_name;
  END IF;
  SELECT COALESCE(online_state(_uid), 0) INTO _state;
  SELECT IFNULL(domain_id, 0) FROM drumate WHERE id=_uid INTO _domain_id;

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
    -- Who is told about _uid's presence, and whose presence _uid is told
    -- about (contact.connection_status reads the same rows): everyone the
    -- Inbox can open a direct chat with, not only the saved contacts --
    -- the peers of every direct conversation (p2p_time) and the same-domain
    -- colleagues chat_rooms lists. Saved contacts alone left a peer reached
    -- from a workspace or an org stuck on the state read when the Inbox
    -- opened: their log-in and log-out never pushed, so they stayed Offline.
    -- The uid-only UNION de-duplicates a contact who is also a colleague;
    -- names come from the yellow page so the row shape stays the same.
    SET @s = CONCAT(
      "SELECT ",
      quote(_uid), " user_id, ",
      _state , " my_state, ",
      quote(_uid), " my_id, ",
      "yp.online_state(s.uid) his_state, ",
      "s.uid his_id, s.uid, du.firstname, du.lastname, s.id, s.server ",
      "FROM (",
        "SELECT uid FROM ", _db_name, ".contact WHERE uid IS NOT NULL ",
        "UNION SELECT peer_id FROM ", _db_name, ".p2p_time ",
        "UNION SELECT id FROM drumate WHERE domain_id = ", _domain_id,
          " AND domain_id > 1 AND IFNULL(json_value(profile, '$.category'), '') <> 'system'",
      ") p ",
      "INNER JOIN socket s ON s.uid = p.uid ",
      "LEFT JOIN drumate du ON du.id = p.uid ",
      "WHERE s.state = 'active' AND p.uid <> ", quote(_uid)
    );

    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END$

DELIMITER ;
