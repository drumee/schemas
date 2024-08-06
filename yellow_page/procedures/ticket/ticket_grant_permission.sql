DELIMITER $


DROP PROCEDURE IF EXISTS `ticket_grant_permission`$
CREATE PROCEDURE `ticket_grant_permission`( _new_uid VARCHAR(16))
BEGIN
 DECLARE _sys_id INT;
 DECLARE _temp_sys_id INT;
 DECLARE _sb_db VARCHAR(1000) ;
 DECLARE _uid VARCHAR(16) ;
 DECLARE _inner_sys_id INT;
 DECLARE _inner_temp_sys_id INT;
 DECLARE _support_domain_id INT;
 DECLARE _user_domain_id INT; 
 
 DECLARE _support_user_id VARCHAR(16) DEFAULT NULL;
 DECLARE _user_id VARCHAR(16) DEFAULT NULL;


  SELECT conf_value  FROM yp.sys_conf WHERE  conf_key = 'support_domain' INTO _support_domain_id; 

  IF _new_uid IS NOT NULL THEN 
    SELECT domain_id FROM yp.privilege WHERE uid = _new_uid INTO _user_domain_id;
    SELECT _new_uid  WHERE _user_domain_id = _support_domain_id  INTO  _support_user_id; 
    SELECT _new_uid  WHERE _user_domain_id <> _support_domain_id  INTO  _user_id; 
  END IF; 

  
  SELECT 0 INTO _sys_id; 
  SELECT h.sys_id  FROM entity e INNER JOIN yp.hub h ON e.id = h.id  
  WHERE h.sys_id > 0  AND   e.area = 'restricted' AND e.type='hub' AND h.owner_id = IFNULL(_user_id, h.owner_id)
  ORDER BY h.sys_id ASC LIMIT 1 INTO _sys_id;
 
  WHILE _sys_id <> 0 DO
    SELECT e.db_name FROM entity e INNER JOIN yp.hub h ON e.id = h.id  
     WHERE h.sys_id = _sys_id  INTO _sb_db;

      -- SET @st = CONCAT('SELECT ', _sb_db ,'. node_id_from_path("/__ticket__") INTO @nid');
      -- PREPARE stamt FROM @st;
      -- EXECUTE stamt ;
      -- DEALLOCATE PREPARE stamt; 

      SELECT 0 INTO _inner_sys_id; 
      SELECT sys_id  FROM privilege WHERE sys_id > 0  and  domain_id = _support_domain_id  AND uid= IFNULL(_support_user_id ,uid ) ORDER BY sys_id ASC LIMIT 1 INTO _inner_sys_id;
    

      WHILE _inner_sys_id <> 0 DO
        SELECT uid FROM privilege WHERE sys_id = _inner_sys_id  INTO _uid;
        SET @st = CONCAT('CALL  ', _sb_db ,'.permission_grant(?,?,0,15,"system","ticketpermission")');
        PREPARE stamt FROM @st;
        EXECUTE stamt USING "*",_uid ;
        DEALLOCATE PREPARE stamt; 

        SELECT _inner_sys_id INTO  _inner_temp_sys_id ;  
        SELECT 0 INTO  _inner_sys_id ; 
        SELECT IFNULL(sys_id,0)  FROM privilege WHERE sys_id >_inner_temp_sys_id AND  domain_id = _support_domain_id AND uid= IFNULL(_support_user_id ,uid )   ORDER BY sys_id ASC  LIMIT 1 INTO _inner_sys_id;

      END WHILE;

    SELECT _sys_id INTO  _temp_sys_id ;  
    SELECT 0 INTO  _sys_id ; 
    SELECT IFNULL(h.sys_id,0)  FROM entity e INNER JOIN yp.hub h ON e.id = h.id  
    WHERE h.sys_id >_temp_sys_id AND  area = 'restricted'  AND e.type='hub' AND h.owner_id = IFNULL(_user_id, h.owner_id)
    ORDER BY h.sys_id ASC  LIMIT 1 INTO _sys_id;
  END WHILE;
END$





DELIMITER ;
