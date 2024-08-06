DELIMITER $



--  for job
  DROP PROCEDURE IF EXISTS `renewal_expiry`$
  CREATE PROCEDURE `renewal_expiry`()
  BEGIN
  
    SELECT  
      r.next_renewal_time,
      r.next_action,
      r.subscription_id,
      r.entity_id,
      d.id ,
      d.fullname,
      d.email,
      r.next_action_time,
     JSON_VALUE(d.profile, '$.lang' ) lang,
     TIMESTAMPDIFF (DAY , FROM_UNIXTIME(r.next_renewal_time), FROM_UNIXTIME(r.next_action_time)) days_since,
     UNIX_TIMESTAMP(DATE_ADD(FROM_UNIXTIME(r.next_renewal_time), INTERVAL 181 DAY)) last_time
    FROM 
      renewal  r 
    INNER JOIN drumate d ON d.id = r.entity_id 
    WHERE next_action_time <= UNIX_TIMESTAMP();

  END $

DELIMITER ;

