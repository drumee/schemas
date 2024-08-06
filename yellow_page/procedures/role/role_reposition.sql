DELIMITER $

DROP PROCEDURE IF EXISTS `role_reposition`$
CREATE PROCEDURE `role_reposition`(
  IN _roles MEDIUMTEXT
)
BEGIN
  DECLARE _i INTEGER DEFAULT 0;
  DROP TABLE IF EXISTS __tmp_position;
  CREATE TEMPORARY TABLE __tmp_position(
    `position` INTEGER,
    `id` varchar(16) DEFAULT NULL
  ); 

  WHILE _i < JSON_LENGTH(_roles) DO 
    -- UPDATE media SET rank = _i 
    --   WHERE id = JSON_UNQUOTE(JSON_EXTRACT(_nodes, CONCAT("$[", _i, "]")));
    INSERT INTO __tmp_position 
      SELECT _i, JSON_UNQUOTE(JSON_EXTRACT(_roles, CONCAT("$[", _i, "]")));
    SELECT _i + 1 INTO _i;
  END WHILE;
  UPDATE role m INNER JOIN __tmp_position t ON m.id=t.id SET m.position = t.position ;
  SELECT * FROM __tmp_position;
  DROP TABLE __tmp_position;
END $



DELIMITER ;