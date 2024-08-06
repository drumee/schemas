DELIMITER $



--   to get users current or last renewal status
  DROP PROCEDURE IF EXISTS `renewal_get_next`$
  CREATE PROCEDURE `renewal_get_next`(
    IN _entity_id VARCHAR(16) CHARACTER SET ascii,
    IN _ctime INT(11)
    )
  BEGIN

    DECLARE  _plan varchar(30) ;
    DECLARE _period varchar(30) ;
    DECLARE _recurring  INT(11) ; 
    DECLARE _start_time int(11) ;
    DECLARE _next_renewal_time int(11) ;
    DECLARE _expired int(11) default 0  ;
    DECLARE _canceled int(11) default  0 ;
    DECLARE _url VARCHAR(2000)  ;




    IF _ctime IN (0,'') THEN 
    SELECT UNIX_TIMESTAMP() INTO  _ctime;
    END IF;
    

    SELECT 'advanced' INTO _plan; 
    SELECT 'company' FROM entity WHERE id=_entity_id AND dom_id > 1 INTO _plan;

    SELECT 
       CASE WHEN
          ( CASE WHEN   cancel_time IS NULL 
            THEN UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(next_renewal_time), INTERVAL 7 DAY))  
            ELSE next_renewal_time END )
         <=  _ctime  THEN _plan ELSE plan END,
        period,recurring ,next_renewal_time, 
        CASE WHEN
          ( CASE WHEN   cancel_time IS NULL 
            THEN UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(next_renewal_time), INTERVAL 7 DAY))  
            ELSE next_renewal_time END )
         <=  _ctime  THEN 1 ELSE 0 END,
        CASE WHEN cancel_time IS NOT NULL AND  next_renewal_time > _ctime THEN 1 ELSE 0 END
    FROM renewal 
    WHERE entity_id = _entity_id 
       -- AND next_renewal_time >= UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(UNIX_TIMESTAMP()), INTERVAL -30 DAY))
    INTO
      _plan , _period,_recurring ,_next_renewal_time , _expired ,_canceled;




    SELECT  
        url  
    FROM 
      renewal_failed rf 
      INNER JOIN subscription_new s ON s.subscription_id = rf.subscription_id AND s.entity_id = rf.entity_id
      INNER JOIN renewal r ON r.subscription_id = rf.subscription_id AND r.entity_id = rf.entity_id
    WHERE 
        rf.entity_id = _entity_id  
        -- AND s.status<>'incomplete'
    INTO _url;


    SELECT  
    _plan plan, 
    _period period,
    _recurring recurring ,
    _next_renewal_time next_renewal_time , 
    _expired is_expired , 
    _canceled is_canceled,
    CASE WHEN _url IS NULL THEN 0 ELSE 1 END is_payment_failed,
    _url   payment_link;


  END $

DELIMITER ;

