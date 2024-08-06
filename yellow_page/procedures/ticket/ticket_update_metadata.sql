DELIMITER $

DROP PROCEDURE IF EXISTS `ticket_update_metadata`$
CREATE PROCEDURE `ticket_update_metadata`(
  IN _ticket_id  int(11),
  IN _data JSON 
  )
BEGIN
DECLARE _value VARCHAR(1024);
  DECLARE _path VARCHAR(100);
  DECLARE _paths VARCHAR(1024);
  DECLARE _i TINYINT(4) DEFAULT 0;

  SELECT JSON_ARRAY(
    "status"
  ) INTO _paths;
  WHILE _i < JSON_LENGTH(_paths) DO 
    SELECT read_json_array(_paths, _i) INTO _path;
    SELECT get_json_object(_data, _path) INTO _value;
    -- SELECT _i, _path, _value;
    IF _value IS NOT NULL THEN 
      UPDATE ticket SET `metadata` = 
        JSON_SET(`metadata`, CONCAT("$.",_path), _value) WHERE ticket_id=_ticket_id;
    END IF;
    SELECT _i + 1 INTO _i;
  END WHILE;

  SELECT 
      t.ticket_id,
      t.ticket_id message,  
      t.uid,
      t.metadata,
      t.status,
      (SELECT IF(COUNT(*), 1, 0) FROM yp.socket soc WHERE soc.uid=t.uid AND state='active' ) is_online,
      0 room_count,
      d.firstname, d.lastname, d.fullname , o.name org_name, t.utime
    FROM 
      yp.ticket t
      INNER JOIN yp.drumate d  ON t.uid =d.id
      INNER JOIN yp.organisation o ON o.domain_id= d.domain_id
    WHERE   
      t.ticket_id =_ticket_id;

  -- SELECT * FROM ticket WHERE ticket_id=_ticket_id;
END $


DELIMITER ;
