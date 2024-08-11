DELIMITER $

DROP PROCEDURE IF EXISTS `add_intial_calendar`$
CREATE PROCEDURE `add_intial_calendar`()
    BEGIN
        DECLARE _check_any INT(1);
        DECLARE _owner_id VARCHAR(16);

        SET _check_any = 0;
        SELECT 1 FROM calendar WHERE category = 'own' LIMIT 1 INTO _check_any;

    IF _check_any =0 THEN
            SELECT id FROM yp.entity WHERE db_name=database() INTO _owner_id;
            CALL add_calendar('My calendar',null,_owner_id,1,0);
    END IF ;
END$ 



DROP PROCEDURE IF EXISTS `chk_name_calendar`$
CREATE PROCEDURE `chk_name_calendar`(
    _name VARCHAR(255),
    _calendar_id  VARCHAR(16))
BEGIN


    IF _calendar_id IS NOT NULL THEN      
        SELECT calendar_id   FROM calendar  WHERE  name = _name AND calendar_id != _calendar_id; 
    ELSE 
        SELECT calendar_id   FROM calendar  WHERE  name = _name; 
    END IF;
   

END$ 


DROP PROCEDURE IF EXISTS `chk_default_calendar`$
CREATE PROCEDURE `chk_default_calendar`(
    _is_default  BOOLEAN,
    _calendar_id  VARCHAR(16))
BEGIN


    SELECT calendar_id  FROM calendar  
    WHERE  is_default = 1  AND _is_default = 0  AND calendar_id = _calendar_id
    LIMIT 1; 
   

END$ 





DROP PROCEDURE IF EXISTS `show_calendar`$
CREATE PROCEDURE `show_calendar`(
     _calendar_id  VARCHAR(16)
)
BEGIN

    IF _calendar_id ='' THEN
        SELECT NULL INTO _calendar_id ; 
    END IF ;

    CALL add_intial_calendar();
    

   SELECT * FROM 
    (
        SELECT 
            calendar_id,
            name,
            color,
            category,
            owner_id,
            is_selected,
            is_default,
            ctime
        FROM calendar
        WHERE  calendar_id = IFNULL(_calendar_id, calendar_id)
        AND category = 'own'
    UNION 
        SELECT 
            calendar_id,
            CONCAT(firstname, " ", lastname) name,
            color,
            cl.category,
            owner_id,
            is_selected,
            is_default,
            cl.ctime
        FROM calendar cl
        INNER JOIN contact c on c.uid= cl.owner_id
        WHERE  calendar_id = IFNULL(_calendar_id, calendar_id)
        AND  cl.category = 'other'
    ) A
    ORDER BY 
        category DESC, name  ASC;
END$ 


DROP PROCEDURE IF EXISTS `delete_calendar`$
CREATE PROCEDURE `delete_calendar`(
    _calendar_id  VARCHAR(16) ,
    _owner_id  VARCHAR(16)
)
BEGIN
   
    UPDATE agenda SET  calendar_id = NULL WHERE calendar_id = _calendar_id;
    DELETE FROM calendar WHERE calendar_id = _calendar_id AND owner_id = _owner_id ;

    -- CALL show_calendar(null);
END$


DROP PROCEDURE IF EXISTS `select_calendar`$
CREATE PROCEDURE `select_calendar`(
    _calendar_ids MEDIUMTEXT
)
BEGIN
    DECLARE _calendar_id  VARCHAR(16);
    DECLARE _i INTEGER DEFAULT 0;


     UPDATE calendar SET  is_selected = 0;

    WHILE _i < JSON_LENGTH(_calendar_ids) DO 
    
        SELECT JSON_UNQUOTE(JSON_EXTRACT(_calendar_ids, CONCAT("$[", _i, "]")))  INTO _calendar_id ;
        UPDATE calendar SET  is_selected = 1 WHERE calendar_id =_calendar_id;
        SELECT _i + 1 INTO _i;
    END WHILE;
END $



DROP PROCEDURE IF EXISTS `modify_calendar`$
CREATE PROCEDURE `modify_calendar`(
    _calendar_id  VARCHAR(16),   
    _name VARCHAR(255),
    _color VARCHAR(10),
    _owner_id  VARCHAR(16),
    _is_selected  BOOLEAN ,
    _is_default  BOOLEAN 
)
BEGIN

    IF IFNULL(_is_default,0) = 1 THEN 
        UPDATE calendar SET  is_default = 0  WHERE is_default = 1  ;
    END IF; 

    UPDATE calendar SET  is_selected = _is_selected, is_default = _is_default , name  =_name ,color= _color WHERE owner_id = _owner_id 
    AND calendar_id = _calendar_id;
    
    -- CALL show_calendar(_calendar_id);

END$



DROP PROCEDURE IF EXISTS `add_calendar`$
CREATE PROCEDURE `add_calendar`(
    _name VARCHAR(255),
    _color VARCHAR(10),
    _owner_id  VARCHAR(16),
    _is_default  BOOLEAN,
    _is_show_result   BOOLEAN
)
BEGIN
    DECLARE _calendar_id VARCHAR(16); 
    DECLARE _drumate_id  VARCHAR(16);
    DECLARE _category  VARCHAR(16);

  
    SELECT id FROM yp.entity WHERE db_name=database() INTO _drumate_id;
    SELECT CASE WHEN _owner_id = _drumate_id THEN 'own' ELSE 'other' END INTO _category; 
    SELECT  yp.uniqueId() INTO _calendar_id; 
    
    IF _category = 'other' THEN
      
      SELECT  _owner_id INTO _calendar_id; 
    
    END IF ;


    IF IFNULL(_is_default,0) = 1 THEN 
    
        UPDATE calendar SET  is_default = 0 WHERE is_default = 1 ;
    
    END IF; 

  
        INSERT INTO calendar (calendar_id,name,color,category,owner_id,is_selected,is_default,ctime)
        SELECT _calendar_id,_name,_color,_category,_owner_id,0,_is_default,UNIX_TIMESTAMP()  ON DUPLICATE KEY UPDATE ctime = UNIX_TIMESTAMP(),is_default=_is_default ;
  
    IF _is_show_result = 1 THEN    
        CALL show_calendar(_calendar_id);
    END IF;
END$ 



DROP PROCEDURE IF EXISTS `list_agenda`$
CREATE PROCEDURE `list_agenda`(
    _ftime INT(11),
    _ttime INT(11)
    )
BEGIN

    SELECT 
        a.agenda_id,
        a.name agenda_name,
        a.place,
        a.category,
        c.calendar_id,
        a.owner_id,
        a.stime,
        a.etime,
        CASE WHEN c.category ='other' THEN CONCAT(con.firstname, " ", con.lastname)
         ELSE c.name END  calendar_name,
        c.color

    FROM 
    agenda a 
    INNER JOIN calendar c 
    ON CASE WHEN c.is_default =1  THEN IFNULL(c.calendar_id,'-99') ELSE c.calendar_id END  = IFNULL(a.calendar_id,'-99')
    LEFT JOIN contact con on con.uid= c.owner_id
    WHERE 
    c.is_selected = 1 AND 
     (
        ( _ftime  between stime and etime) OR   
        ( _ttime  between stime and etime) OR   
        ( stime  between _ftime and _ttime) OR 
        ( etime  between _ftime and _ttime) 
      
      ) ;
END$ 



DROP PROCEDURE IF EXISTS `show_detail_map_agenda`$
CREATE PROCEDURE `show_detail_map_agenda`(
     _agenda_id  VARCHAR(16)
)
BEGIN
    
    SELECT  
        c.id contact_id,
        CONCAT(c.firstname, " ", c.lastname) fullname, 
        c.email,
        c.uid 
    FROM map_agenda ma 
    INNER JOIN contact c ON c.id = ma.contact_id
    WHERE  ma.agenda_id =_agenda_id;

END$ 


DROP PROCEDURE IF EXISTS `show_detail_agenda`$
CREATE PROCEDURE `show_detail_agenda`(
     _agenda_id  VARCHAR(16)
)
BEGIN
    
    SELECT 
        a.agenda_id,
        a.name agenda_name,
        a.place,
        a.category,
        c.calendar_id,
        a.owner_id,
        a.stime,
        a.etime,
        CASE WHEN c.category ='other' THEN CONCAT(con.firstname, " ", con.lastname) ELSE c.name END  calendar_name
        
    FROM 
    agenda a 
    INNER JOIN calendar c 
    -- ON CASE WHEN c.is_default =1  THEN '-99' ELSE c.calendar_id END  = IFNULL(a.calendar_id,'-99')
    ON CASE WHEN c.is_default =1  THEN IFNULL(c.calendar_id,'-99') ELSE c.calendar_id END  = IFNULL(a.calendar_id,'-99')
    LEFT JOIN contact con on con.uid= c.owner_id
    WHERE agenda_id = _agenda_id; 

END$ 


DROP PROCEDURE IF EXISTS `delete_agenda`$
CREATE PROCEDURE `delete_agenda`( _agenda_id VARCHAR(16))
BEGIN
    
    DECLARE   _category  VARCHAR(20);
    DECLARE   _owner_id  VARCHAR(16);
    
    
    SELECT category ,owner_id FROM agenda WHERE agenda_id = _agenda_id INTO _category, _owner_id;
    DELETE FROM agenda WHERE agenda_id = _agenda_id;

    IF _category = 'other' AND (IFNULL ((SELECT 1 FROM agenda WHERE owner_id = _owner_id AND category = 'other'),0) =0) THEN
    
        DELETE FROM calendar WHERE owner_id = _owner_id;
    
    END IF;
  
    

END$


DROP PROCEDURE IF EXISTS `delete_map_agenda`$
CREATE PROCEDURE `delete_map_agenda`( _agenda_id VARCHAR(16))
BEGIN

    DELETE FROM map_agenda WHERE agenda_id = _agenda_id;

END$



DROP PROCEDURE IF EXISTS `remove_agenda`$
CREATE PROCEDURE `remove_agenda`(
    _agenda_id VARCHAR(16)
)
BEGIN
    
    DECLARE _lvl INT(4);
    DECLARE _drumate_id VARCHAR(16);
    DECLARE _drumate_db VARCHAR(255); 
    

    DROP TABLE IF EXISTS _map_agenda;
    CREATE TEMPORARY TABLE _map_agenda(
            `drumate_id` varchar(16) NOT NULL,
            `is_checked` boolean default 0
        );
    
    INSERT INTO _map_agenda (drumate_id)
    SELECT uid FROM map_agenda WHERE  agenda_id = _agenda_id AND uid IS NOT NULL;

    WHILE (IFNULL((SELECT 1 FROM _map_agenda  WHERE  is_checked = 0 LIMIT 1 ),0)  = 1 ) AND IFNULL(_lvl,0) < 1000 DO
        SELECT NULL,NULL  INTO _drumate_id ,_drumate_db;
        SELECT drumate_id  FROM _map_agenda WHERE is_checked = 0 LIMIT 1  INTO _drumate_id;
        SELECT db_name FROM yp.entity WHERE id=_drumate_id INTO _drumate_db;
        
            SET @st = CONCAT(
            'CALL ', _drumate_db ,'.delete_map_agenda (', QUOTE(_agenda_id) ,')');
            PREPARE stamt FROM @st;
            EXECUTE stamt;
            DEALLOCATE PREPARE stamt; 

            SET @st = CONCAT(
            'CALL ', _drumate_db ,'.delete_agenda (', QUOTE(_agenda_id) ,')');
            PREPARE stamt FROM @st;
            EXECUTE stamt;
            DEALLOCATE PREPARE stamt; 

        UPDATE _map_agenda SET is_checked =  1 WHERE drumate_id =_drumate_id; 
        SELECT IFNULL(_lvl,0) + 1 INTO _lvl;
    END WHILE;


    CALL delete_map_agenda(_agenda_id);
    CALL delete_agenda(_agenda_id);


END$ 



DROP PROCEDURE IF EXISTS `add_map_agenda`$
CREATE PROCEDURE `add_map_agenda`(
    _agenda_id VARCHAR(16),
    _contact_id VARCHAR(16), 
    _drumate_id VARCHAR(16)
)
BEGIN

    INSERT INTO map_agenda (agenda_id,contact_id,uid,ctime)   
    SELECT _agenda_id,_contact_id, _drumate_id ,UNIX_TIMESTAMP() ;
END$



DROP PROCEDURE IF EXISTS `insert_agenda`$
CREATE PROCEDURE `insert_agenda`(
    _agenda_id VARCHAR(16),
    _name  VARCHAR(255),
    _place VARCHAR(255),
    _category VARCHAR(16),
    _owner_id VARCHAR(16),
    _calendar_id VARCHAR(16),
    _stime int(11) ,
    _etime int(11) 
   
)
BEGIN
    DECLARE _time int(11) unsigned;
    SELECT UNIX_TIMESTAMP() INTO _time; 

    IF _category = 'own' AND (IFNULL ((SELECT 1 FROM calendar WHERE owner_id = _owner_id AND category = 'own' LIMIT 1),0) =0) THEN
        CALL add_intial_calendar();
    END IF;

    INSERT INTO agenda (agenda_id,name,place,category,owner_id,stime,etime,calendar_id,ctime,mtime)
    SELECT _agenda_id,_name,_place,_category,_owner_id,_stime,_etime,_calendar_id,_time,_time;
END$


DROP PROCEDURE IF EXISTS `add_agenda`$
CREATE PROCEDURE `add_agenda`(
    _name VARCHAR(255),
    _place VARCHAR(255),
    _contact_ids MEDIUMTEXT,
    _stime int(11) ,
    _etime int(11) ,  
    _owner_id  VARCHAR(16),
    _calendar_id VARCHAR(16)   
    
)
BEGIN
    DECLARE _agenda_id VARCHAR(16); 

    DECLARE _category  VARCHAR(16);
    DECLARE _i INTEGER DEFAULT 0;
    
    DECLARE _contact_id VARCHAR(16);
    DECLARE _drumate_id VARCHAR(16);

    DECLARE _drumate_db VARCHAR(255); 
    DECLARE _time int(11) unsigned;

    IF _name = '' THEN 
        SELECT NULL INTO _name;
    END IF; 

    IF _place = '' THEN 
        SELECT NULL INTO _place;
    END IF;
    
    IF _etime = '' or _etime = 0 THEN 
        SELECT NULL INTO _etime;
    END IF;

    IF _calendar_id = '' THEN
        SELECT NULL INTO _calendar_id;
    END IF;


    SELECT  yp.uniqueId() INTO _agenda_id; 
    SELECT UNIX_TIMESTAMP() INTO _time; 
    SELECT id FROM yp.entity WHERE db_name=database() INTO _drumate_id;
    SELECT CASE WHEN _owner_id = _drumate_id THEN 'own' ELSE 'other' END INTO _category; 


    CALL insert_agenda(_agenda_id,_name,_place,_category,_owner_id,_calendar_id,_stime,_etime);

    UPDATE calendar SET is_selected=1  WHERE calendar_id=_calendar_id;
     
    
    WHILE _i < JSON_LENGTH(_contact_ids) DO 
        SELECT NULL,NULL , NULL INTO _drumate_id ,_drumate_db, _contact_id;
        
        SELECT JSON_UNQUOTE(JSON_EXTRACT(_contact_ids, CONCAT("$[", _i, "]")))  INTO _contact_id ;
        
        
        SELECT  (SELECT id FROM contact WHERE id = _contact_id) INTO _contact_id; 
        SELECT db_name FROM yp.entity WHERE id=_contact_id INTO _drumate_db;
        SELECT *  FROM (SELECT _contact_id ) a WHERE  _drumate_db IS NOT NULL INTO _drumate_id ;     

      

        IF _contact_id IS NOT NULL THEN
            CALL add_map_agenda (_agenda_id,_contact_id, _drumate_id);
        END IF;

        IF _drumate_id IS NOT NULL THEN


            SET @st = CONCAT(
             'CALL ', _drumate_db ,'.add_map_agenda (', QUOTE(_agenda_id) ,',', QUOTE(_owner_id),',', QUOTE(_owner_id),')');
            PREPARE stamt FROM @st;
            EXECUTE stamt;
            DEALLOCATE PREPARE stamt; 

            SET @st = CONCAT(
            'CALL ', _drumate_db ,'.add_calendar(', QUOTE(_owner_id) ,',null,',  QUOTE(_owner_id),',0,0 )' );
            PREPARE stamt FROM @st;
            EXECUTE stamt;
            DEALLOCATE PREPARE stamt; 


           
            SET @st = CONCAT(
            'CALL  ', _drumate_db ,'.insert_agenda(', QUOTE(_agenda_id) ,',', QUOTE(_name),',',
            IFNULL(QUOTE(_place),"NULL"),',"other",',QUOTE(_owner_id),',',QUOTE(_owner_id),',',_stime,',',
            IFNULL(_etime,"NULL"),')');
            
            PREPARE stamt FROM @st;
            EXECUTE stamt;
            DEALLOCATE PREPARE stamt; 

     END IF;
        
        
        SELECT _i + 1 INTO _i;
    END WHILE;
        
    CALL show_detail_agenda(_agenda_id);

END$ 





DROP PROCEDURE IF EXISTS `modify_agenda`$
CREATE PROCEDURE `modify_agenda`(
    _agenda_id VARCHAR(16),
    _name VARCHAR(255),
    _place VARCHAR(255),
    _contact_ids TEXT,
    _stime int(11) ,
    _etime int(11) ,  
    _owner_id  VARCHAR(16),
    _calendar_id VARCHAR(16)
    
)
BEGIN
    
    DECLARE _time int(11) unsigned;
    DECLARE _lvl INT(4);
    DECLARE _drumate_id VARCHAR(16);
    DECLARE _drumate_db VARCHAR(255); 
    DECLARE _category  VARCHAR(16);
    DECLARE _i INTEGER DEFAULT 0;
    DECLARE _contact_id VARCHAR(16);
   


    SELECT UNIX_TIMESTAMP() INTO _time;

    DROP TABLE IF EXISTS _map_agenda;
       CREATE TEMPORARY TABLE _map_agenda(
            `drumate_id` varchar(16) NOT NULL,
            `is_checked` boolean default 0
        );
    INSERT INTO _map_agenda (drumate_id)
    SELECT uid FROM map_agenda WHERE  agenda_id = _agenda_id AND uid IS NOT NULL;

       

     WHILE (IFNULL((SELECT 1 FROM _map_agenda  WHERE  is_checked = 0 LIMIT 1 ),0)  = 1 ) AND IFNULL(_lvl,0) < 1000 DO
        SELECT NULL,NULL  INTO _drumate_id ,_drumate_db;
        SELECT drumate_id  FROM _map_agenda WHERE is_checked = 0 LIMIT 1  INTO _drumate_id;
       
        SELECT db_name FROM yp.entity WHERE id=_drumate_id INTO _drumate_db;
            SET @st = CONCAT(
             'CALL ', _drumate_db ,'.delete_map_agenda (', QUOTE(_agenda_id) ,')');
            PREPARE stamt FROM @st;
            EXECUTE stamt;
            DEALLOCATE PREPARE stamt; 

            SET @st = CONCAT(
            'CALL ', _drumate_db ,'.delete_agenda(', QUOTE(_agenda_id) ,')');
            PREPARE stamt FROM @st;
            EXECUTE stamt;
            DEALLOCATE PREPARE stamt; 
 

        UPDATE _map_agenda SET is_checked =  1 WHERE drumate_id =_drumate_id; 
        SELECT IFNULL(_lvl,0) + 1 INTO _lvl;
     END WHILE;

    SELECT id FROM yp.entity WHERE db_name=database() INTO _drumate_id;
    SELECT CASE WHEN _owner_id = _drumate_id THEN 'own' ELSE 'other' END INTO _category;  

    IF _name = '' THEN 
        SELECT NULL INTO _name;
    END IF; 

    IF _place = '' THEN 
        SELECT NULL INTO _place;
    END IF;
    
    IF _etime = '' or _etime = 0 THEN 
        SELECT NULL INTO _etime;
    END IF;

    IF _calendar_id = '' THEN
        SELECT NULL INTO _calendar_id;
    END IF;

    UPDATE agenda
    SET name= _name,place=_place,
    category=_category,owner_id=_owner_id,calendar_id=_calendar_id,stime=_stime,etime=_etime,
    mtime= _time
    WHERE agenda_id= _agenda_id;

    UPDATE calendar SET is_selected=1  WHERE calendar_id=_calendar_id;

    CALL delete_map_agenda(_agenda_id);   
  


    WHILE _i < JSON_LENGTH(_contact_ids) DO 
        SELECT NULL,NULL , NULL INTO _drumate_id ,_drumate_db, _contact_id;
        
        SELECT JSON_UNQUOTE(JSON_EXTRACT(_contact_ids, CONCAT("$[", _i, "]")))  INTO _contact_id ;
        
        
        SELECT  (SELECT id FROM contact WHERE id = _contact_id) INTO _contact_id; 
        SELECT db_name FROM yp.entity WHERE id=_contact_id INTO _drumate_db;
        SELECT *  FROM (SELECT _contact_id ) a WHERE  _drumate_db IS NOT NULL INTO _drumate_id ;     

        IF _contact_id IS NOT NULL THEN
            CALL add_map_agenda (_agenda_id,_contact_id, _drumate_id);
        END IF;



        IF _drumate_id IS NOT NULL THEN


            SET @st = CONCAT(
            'CALL ', _drumate_db ,'.add_map_agenda (', QUOTE(_agenda_id) ,',', QUOTE(_owner_id),',', QUOTE(_owner_id),')');
            PREPARE stamt FROM @st;
            EXECUTE stamt;
            DEALLOCATE PREPARE stamt; 

            SET @st = CONCAT(
            'CALL ', _drumate_db ,'.add_calendar (', QUOTE(_owner_id) ,',null,',  QUOTE(_owner_id),',0,0)' );
            PREPARE stamt FROM @st;
            EXECUTE stamt;
            DEALLOCATE PREPARE stamt; 

            SET @st = CONCAT(
            'CALL  ', _drumate_db ,'.insert_agenda(', QUOTE(_agenda_id) ,',', QUOTE(_name),',',
            IFNULL(QUOTE(_place),"NULL"),',"other",',QUOTE(_owner_id),',',QUOTE(_owner_id),',',_stime,',',
            IFNULL(_etime,"NULL"),')'); 
            PREPARE stamt FROM @st;
            EXECUTE stamt;
            DEALLOCATE PREPARE stamt; 

     END IF;
        
        SELECT _i + 1 INTO _i;
    END WHILE;
        
    CALL show_detail_agenda(_agenda_id);

END$ 




DELIMITER ;

