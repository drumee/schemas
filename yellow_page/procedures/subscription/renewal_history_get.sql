DELIMITER $



--  for invoice
  DROP PROCEDURE IF EXISTS `renewal_history_get`$
  CREATE PROCEDURE `renewal_history_get`(
    IN _entity_id VARCHAR(16) ,
    IN _page INT(6)

    )
  BEGIN
     DECLARE _range bigint;
     DECLARE _offset bigint;
     DECLARE _payment_intent_id VARCHAR(30); 
     CALL pageToLimits(_page, _offset, _range);
   
    SELECT payment_intent_id FROM renewal WHERE entity_id =_entity_id INTO _payment_intent_id;

    SELECT 
      _page as `page`,
      entity_id,
      invoice_id,
      status,
      -- subscription_id,payment_intent_id,
      plan,
      period,   
      recurring, 
      ctime paidtime, 
      price,offer_price,
      renewal_amount,stime,etime,
      FROM_UNIXTIME(stime)  sdate, 
      FROM_UNIXTIME(etime)  edate, 
      --  price,offer_price,renewal_amount,stime,etime,status,metadata , 
      CASE WHEN _payment_intent_id = payment_intent_id THEN 'current' else 'old' END flag,
      pdf,url

    FROM 
      renewal_history r WHERE entity_id =_entity_id 
    ORDER BY stime DESC  LIMIT _offset, _range;
  END $
DELIMITER ;

