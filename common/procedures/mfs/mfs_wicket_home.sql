DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_wicket_home`$
CREATE PROCEDURE `mfs_wicket_home`(
  IN _uid VARCHAR(16)
)
BEGIN
  DECLARE _wicket_db_name VARCHAR(255);
  DECLARE _user_db_name VARCHAR(255);
  DECLARE _wicket_id VARCHAR(16);
  DECLARE _uniqueid VARCHAR(16);
  DECLARE _domain_id INTEGER UNSIGNED;

  SELECT h.id FROM 
    yp.hub h INNER JOIN yp.entity e on e.id=h.id
  WHERE h.owner_id=_uid AND `serial`=0 INTO _wicket_id;

  IF _wicket_id IS NULL THEN 
    SELECT db_name FROM yp.entity WHERE id=_uid INTO _user_db_name;
    SELECT domain_id FROM yp.drumate WHERE id=_uid INTO _domain_id;
    SELECT  uniqueId() INTO _uniqueid;
    SELECT  uniqueId() INTO @wicket;
    SET @st1 = CONCAT('CALL ', _user_db_name ,'.desk_create_hub(?, ?)');
    PREPARE stmt1 FROM @st1;
    EXECUTE stmt1 USING  
      JSON_OBJECT("hostname", _uniqueid, "domain_id", _domain_id, "filename",@wicket, "area", 'dmz', "owner_id", _uid),
      JSON_OBJECT("is_wicket",1);        
    DEALLOCATE PREPARE stmt1;
  END IF;
  
  SELECT db_name FROM yp.entity WHERE id=_wicket_id INTO _wicket_db_name;
  SET @st = CONCAT('CALL ', _wicket_db_name ,'.mfs_home()');
  PREPARE stamt FROM @st;
  EXECUTE stamt;
  DEALLOCATE PREPARE stamt;
END $


DELIMITER ;