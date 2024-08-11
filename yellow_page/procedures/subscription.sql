DELIMITER $


DROP PROCEDURE IF EXISTS `payment_initiate`$
-- CREATE PROCEDURE `payment_initiate`(
--    IN _entity_id VARCHAR(16),
--    IN _category varchar(30),
--    IN _amount  float
--   )
-- BEGIN
--   DECLARE _plan varchar(30) CHARACTER SET ascii DEFAULT 'hub' ; 
--   DECLARE _payment_id varchar(16) CHARACTER SET ascii;
--   DECLARE _old_payment_id varchar(16) CHARACTER SET ascii;

--   SELECT uniqueId() INTO _payment_id;

--   SELECT 'pro'  FROM organisation WHERE id = _entity_id INTO _plan;

--   SELECT payment_id FROM payment 
--   WHERE entity_id =_entity_id
--   AND status = 'initiated'
--   INTO _old_payment_id;


--     INSERT INTO payment (payment_id,entity_id,plan,category,status,amount,ctime)
--     SELECT _payment_id,_entity_id,_plan,_category,'initiated',_amount,UNIX_TIMESTAMP()
--     WHERE _old_payment_id IS NULL;

--     SELECT *  FROM payment WHERE payment_id =IFNULL(_old_payment_id , _payment_id);
 
-- END $




DROP PROCEDURE IF EXISTS `payment_paid`$
-- CREATE PROCEDURE `payment_paid`(
--    IN _entity_id VARCHAR(16) CHARACTER SET ascii,
--    IN _payment_id VARCHAR(16) CHARACTER SET ascii 
--   )
-- BEGIN

--     UPDATE payment SET status = 'paid'
--     WHERE payment_id =_payment_id
--     AND entity_id = _entity_id 
--     AND status = 'initiated';

--     SELECT *  FROM payment 
--     WHERE entity_id = _entity_id 
--     AND payment_id =_payment_id;
-- END $


DROP PROCEDURE IF EXISTS `payment_failed`$
-- CREATE PROCEDURE `payment_failed`(
--    IN _entity_id VARCHAR(16) CHARACTER SET ascii,
--    IN _payment_id VARCHAR(16) CHARACTER SET ascii 
--   )
-- BEGIN

--     UPDATE payment SET status = 'failed'
--     WHERE payment_id =_payment_id 
--     AND entity_id = _entity_id 
--     AND status = 'initiated';

--     SELECT *  FROM payment
--     WHERE entity_id = _entity_id 
--     AND payment_id =_payment_id;
-- END $



DROP PROCEDURE IF EXISTS `payment_get`$
-- CREATE PROCEDURE `payment_get`(
--     IN _entity_id VARCHAR(16) CHARACTER SET ascii,
--     IN _payment_id VARCHAR(16) CHARACTER SET ascii 
--   )
-- BEGIN
--   SELECT *  FROM payment 
--   WHERE entity_id = _entity_id  
--   AND payment_id =_payment_id;
-- END $

DROP PROCEDURE IF EXISTS `payment_get_by_status`$
-- CREATE PROCEDURE `payment_get_by_status`(
--     IN _entity_id VARCHAR(16) CHARACTER SET ascii,
--     IN _status VARCHAR(30)  
--   )
-- BEGIN
--   SELECT *  FROM payment 
--   WHERE entity_id = _entity_id  
--   AND status =_status;
-- END $




DROP PROCEDURE IF EXISTS `subscription_get`$
-- CREATE PROCEDURE `subscription_get`(
--    IN _entity_id VARCHAR(16)
--   )
-- BEGIN
-- DECLARE _ntime INT(11); 
--   SELECT UNIX_TIMESTAMP() INTO _ntime;
--   SELECT  entity_id, stime,etime,ctime,mode,
--   CASE WHEN  _ntime >= stime AND etime >= _ntime THEN 'active'
--        WHEN  _ntime < stime THEN 'upcoming' 
--        WHEN  _ntime >  etime THEN 'expired' END flag
--   FROM subscription WHERE entity_id =_entity_id;
-- END $



DROP PROCEDURE IF EXISTS `subscription_update`$
-- CREATE PROCEDURE `subscription_update`(
--    IN _entity_id VARCHAR(16) CHARACTER SET ascii,
--    IN _payment_id VARCHAR(16) CHARACTER SET ascii 
--   )
-- BEGIN
--   DECLARE _etime INT(11);
--   DECLARE _stime INT(11); 
--   DECLARE _ntime INT(11); 
--   DECLARE _category varchar(30) DEFAULT 'unknown';
 
--     SELECT UNIX_TIMESTAMP() INTO _ntime;

--     SELECT max(etime)  FROM subscription WHERE entity_id =_entity_id INTO _etime;
--     SELECT CASE WHEN _etime > _ntime THEN _etime+1 ELSE _ntime END INTO _stime ;

--     SELECT category  FROM payment 
--     WHERE entity_id = _entity_id 
--     AND payment_id =_payment_id
--     AND status = 'paid'  
--     INTO _category;

--    IF (_category !='unknown') THEN
   
--     IF (_category = 'year') THEN
--       SELECT UNIX_TIMESTAMP(DATE_ADD( FROM_UNIXTIME(_stime), INTERVAL 1 YEAR)) INTO _ntime;
--       SELECT UNIX_TIMESTAMP(DATE_ADD( FROM_UNIXTIME(_ntime), INTERVAL -1 DAY)) INTO _ntime;
--       INSERT INTO subscription (payment_id,entity_id, stime,etime,ctime,mode)
--       SELECT _payment_id,_entity_id,_stime,_ntime  ,UNIX_TIMESTAMP(),'paid';
--     ELSE
--       SELECT UNIX_TIMESTAMP(DATE_ADD( FROM_UNIXTIME(_stime), INTERVAL 1 MONTH)) INTO _ntime;
--       SELECT UNIX_TIMESTAMP(DATE_ADD( FROM_UNIXTIME(_ntime), INTERVAL -1 DAY)) INTO _ntime;
--       INSERT INTO subscription (payment_id,entity_id, stime,etime,ctime,mode)
--       SELECT _payment_id,_entity_id,_stime,  _ntime ,UNIX_TIMESTAMP(),'paid';
--     END IF ;

--     UPDATE payment SET status = 'subscribed',
--     utime = UNIX_TIMESTAMP()
--     WHERE payment_id =_payment_id
--     AND entity_id = _entity_id 
--     AND status = 'paid';

--   END IF;
--   SELECT  FROM_UNIXTIME(stime),FROM_UNIXTIME(etime)  FROM subscription WHERE entity_id =_entity_id order by sys_id;

-- END $


DELIMITER ;

-- call payment_initiate ('197e7e69197e7e72','month', 10);
-- call payment_paid ('197e7e69197e7e72','8fb02c3d8fb02c4d');
-- call subscription_update('197e7e69197e7e72','8fb02c3d8fb02c4d');
-- call subscription_get ('197e7e69197e7e72');
-- call yp.subscription_update( '65336c9f65336caf', '5fee242d5fee2439')