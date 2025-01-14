 DELIMITER $

DROP PROCEDURE IF EXISTS `readlog_mark`$
CREATE PROCEDURE `readlog_mark`(
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _hub_id INT(11),
  IN _nid INT(11)
)
BEGIN
  DECLARE _user_db VARCHAR(255);
  DECLARE _hub_db VARCHAR(255);
  DECLARE _cur_db VARCHAR(255);
  DECLARE _filetaype VARCHAR(255);

  SELECT DATABASE() INTO _cur_db;

  SELECT db_name FROM yp.entity WHERE id = _uid INTO _user_db;

  SELECT category FROM media WHERE id=_nid INTO _filetaype;

  IF _filetaype NOT IN ('folder', 'hub') THEN 
    UPDATE readlog SET unread=0 WHERE uid=_uid AND hub_id=_hub_id AND nid=_nid;
  END IF;

  IF _user_db = _cur_db THEN
    IF _filetaype='hub' THEN 
      SELECT db_name FROM yp.entity WHERE id = _nid INTO _hub_db;
      SET @s = CONCAT("UPDATE ", _hub_db, ".readlog SET unread=0 WHERE uid=? AND hub_id=? AND nid=?");
    END IF;
  ELSE
    SET @s = CONCAT("UPDATE ", _user_db, ".readlog SET unread=0 WHERE uid=? AND hub_id=? AND nid=?");
  END IF;

  IF @s IS NOT NULL THEN
    PREPARE stmt FROM @s;
    EXECUTE stmt USING _uid, _hub_id, _nid;
    DEALLOCATE PREPARE stmt; 
  END IF;

END $

DELIMITER ;

