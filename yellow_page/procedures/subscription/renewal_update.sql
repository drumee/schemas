DELIMITER $



  
-- core SP  
DROP PROCEDURE IF EXISTS `renewal_update`$
  CREATE PROCEDURE `renewal_update`(
    IN _status   VARCHAR(16),
    IN _entity_id VARCHAR(16),
    IN _invoice_id varchar(30) ,
    IN _payment_intent_id  VARCHAR(30),
    IN _subscription_id VARCHAR(30),
    IN _plan varchar(30) ,
    IN _period varchar(30) ,
    IN _recurring  INT(11) , 
    IN _start_time int(11), 
    IN _next_renewal_time int(11) ,
    IN _price float,
    IN _offer_price  float,
    IN _renewal_amount float,
    IN _pdf varchar(300) ,
    IN _url varchar(300) ,
    IN _res json
    )
  BEGIN

    DECLARE  _flag  INT;
    SELECT 0 INTO _flag; 

   IF _status <> 'paid' THEN 

      SELECT 
         1 
      FROM 
        renewal_history
      WHERE 
        subscription_id =  _subscription_id AND 
        payment_intent_id = _payment_intent_id AND
        entity_id = entity_id 
      INTO _flag; 

      INSERT INTO renewal_history
          ( entity_id,invoice_id,subscription_id,payment_intent_id,
            plan ,period,recurring, ctime, 
            price,offer_price,renewal_amount,stime,etime,status,metadata,pdf,url
          )
      SELECT 
          _entity_id,_invoice_id,_subscription_id,_payment_intent_id,
          _plan,_period,_recurring,UNIX_TIMESTAMP(),
          _price,_offer_price,_renewal_amount,_start_time,_next_renewal_time,_status,_res ,_pdf,_url
          WHERE _flag = 0 ;

      INSERT INTO renewal_failed
          ( entity_id,invoice_id,subscription_id,payment_intent_id,
            plan ,period,recurring, ctime, 
            price,offer_price,renewal_amount,url
          )
      SELECT 
          _entity_id,_invoice_id,_subscription_id,_payment_intent_id,
          _plan,_period,_recurring,UNIX_TIMESTAMP(),
          _price,_offer_price,_renewal_amount,_url
          WHERE _flag = 0 ;


    END IF ;



    IF _status = 'paid' THEN 


      INSERT INTO renewal_history
            ( entity_id,invoice_id,subscription_id,payment_intent_id,
              plan ,period,recurring, ctime, 
              price,offer_price,renewal_amount,stime,etime,status,metadata,pdf,url
            )
        SELECT 
            _entity_id,_invoice_id,_subscription_id,_payment_intent_id,
            _plan,_period,_recurring,UNIX_TIMESTAMP(),
            _price,_offer_price,_renewal_amount,_start_time,_next_renewal_time,_status,_res ,_pdf,_url
        ON DUPLICATE KEY UPDATE
            status = _status;

        SELECT 1 INTO _flag; 
        SELECT 0 FROM renewal WHERE entity_id = _entity_id AND stime > _start_time INTO _flag;


        IF _flag = 1 THEN 

          SELECT 
          JSON_OBJECT(
          '5'  , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_next_renewal_time), INTERVAL  8 DAY)), 'on', 1 ),
          '6'  , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_next_renewal_time), INTERVAL 31 DAY)), 'on', 1 ),
          '7'  , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_next_renewal_time), INTERVAL 61 DAY)), 'on', 1 ),
          '8'  , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_next_renewal_time), INTERVAL 91 DAY)), 'on', 1 ),
          '9'  , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_next_renewal_time), INTERVAL 121 DAY)), 'on', 1 ),
          '10' , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_next_renewal_time), INTERVAL 151 DAY)), 'on', 1 ),
          '11' , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_next_renewal_time), INTERVAL 158 DAY)), 'on', 1 ),
          '12 ', JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_next_renewal_time), INTERVAL 165 DAY)), 'on', 1 ),
          '13' , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_next_renewal_time), INTERVAL 172 DAY)), 'on', 1 ),
          '14' , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_next_renewal_time), INTERVAL 176 DAY)), 'on', 1 ),
          '15' , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_next_renewal_time), INTERVAL 177 DAY)), 'on', 1 ),
          '16' , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_next_renewal_time), INTERVAL 178 DAY)), 'on', 1 ),
          '17' , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_next_renewal_time), INTERVAL 179 DAY)), 'on', 1 ),
          '18' , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_next_renewal_time), INTERVAL 180 DAY)), 'on', 1 ),
          '19' , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_next_renewal_time), INTERVAL 181 DAY)), 'on', 1 )
         --  '20' , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_next_renewal_time), INTERVAL 29 DAY)), 'on', 1 ),
          

          ) INTO @json;


          INSERT INTO renewal 
            (entity_id,subscription_id,payment_intent_id,
            plan ,period,recurring, stime , next_renewal_time,ctime,metadata)
          SELECT 
            _entity_id,_subscription_id,_payment_intent_id,
            _plan,_period,_recurring,_start_time, _next_renewal_time,UNIX_TIMESTAMP(),@json
          ON DUPLICATE KEY UPDATE
              subscription_id =_subscription_id,
              payment_intent_id =_payment_intent_id,
              plan =_plan,
              period =_period,
              recurring =_recurring ,
              stime = _start_time,
              next_renewal_time = _next_renewal_time,
              ctime =  UNIX_TIMESTAMP(), 
              cancel_time = NULL,
              metadata = @json;

        END IF;

      DELETE FROM renewal_failed WHERE 
        subscription_id =  _subscription_id AND 
        payment_intent_id = _payment_intent_id AND
        entity_id = entity_id ;

    END IF ;


    SELECT * from renewal WHERE entity_id = _entity_id;

  END $


DELIMITER ;

