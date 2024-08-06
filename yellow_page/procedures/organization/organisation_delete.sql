


DELIMITER $


DROP PROCEDURE IF EXISTS `organisation_delete`$
CREATE PROCEDURE `organisation_delete`(
   IN _key VARCHAR(1000)
)
BEGIN
  DECLARE _domain_id INTEGER;
  DECLARE _finished BOOLEAN DEFAULT 0;
  DECLARE _uid VARCHAR(16);

  SELECT domain_id FROM organisation WHERE link = _key OR id=_key
    INTO _domain_id;

  DROP TABLE IF EXISTS _show_users;
  CREATE TEMPORARY TABLE _show_users  AS 
    SELECT `uid` FROM privilege WHERE domain_id=_domain_id;
  BEGIN
    DECLARE dbcursor CURSOR FOR SELECT `uid` FROM _show_users;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 
    OPEN dbcursor;
      FETCH dbcursor INTO _uid;
      WHILE NOT _finished DO
        CALL drumate_delete(_uid);
      FETCH dbcursor INTO _uid;
      END WHILE;
    CLOSE dbcursor;
  END$
  DELETE FROM drumate WHERE domain_id=_domain_id;
  DELETE FROM hub WHERE domain_id=_domain_id;
  DELETE FROM entity WHERE dom_id=_domain_id;
  DELETE FROM vhost WHERE dom_id=_domain_id;
END$
DELIMITER ;