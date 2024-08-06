DELIMITER $

 
  

--   to cancel the subscription
  DROP PROCEDURE IF EXISTS `renewal_cancel_next`$
  CREATE PROCEDURE `renewal_cancel_next`(
    IN _entity_id VARCHAR(16) CHARACTER SET ascii,
    IN _cancel_at INT
    )
  BEGIN


        SELECT 
          JSON_OBJECT(
          '5'  , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_cancel_at), INTERVAL  0 DAY)), 'on', 1 ),
          '6'  , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_cancel_at), INTERVAL 31 DAY)), 'on', 1 ),
          '7'  , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_cancel_at), INTERVAL 61 DAY)), 'on', 1 ),
          '8'  , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_cancel_at), INTERVAL 91 DAY)), 'on', 1 ),
          '9'  , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_cancel_at), INTERVAL 121 DAY)), 'on', 1 ),
          '10' , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_cancel_at), INTERVAL 151 DAY)), 'on', 1 ),
          '11' , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_cancel_at), INTERVAL 158 DAY)), 'on', 1 ),
          '12 ', JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_cancel_at), INTERVAL 165 DAY)), 'on', 1 ),
          '13' , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_cancel_at), INTERVAL 172 DAY)), 'on', 1 ),
          '14' , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_cancel_at), INTERVAL 176 DAY)), 'on', 1 ),
          '15' , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_cancel_at), INTERVAL 177 DAY)), 'on', 1 ),
          '16' , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_cancel_at), INTERVAL 178 DAY)), 'on', 1 ),
          '17' , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_cancel_at), INTERVAL 179 DAY)), 'on', 1 ),
          '18' , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_cancel_at), INTERVAL 180 DAY)), 'on', 1 ),
          '19' , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_cancel_at), INTERVAL 181 DAY)), 'on', 1 )
         --  '20' , JSON_OBJECT( 'date', UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(_next_renewal_time), INTERVAL 29 DAY)), 'on', 1 ),
          

          ) INTO @json;



    UPDATE renewal SET cancel_time = _cancel_at, metadata = @json
    WHERE entity_id = _entity_id;
  END $
DELIMITER ;

