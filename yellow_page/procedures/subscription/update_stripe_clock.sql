DELIMITER $




  DROP PROCEDURE IF EXISTS `update_stripe_clock`$
  CREATE PROCEDURE `update_stripe_clock`(
    IN _clock_id VARCHAR(100),
    IN _flag  int
    
    )
  BEGIN
  
    REPLACE INTO sys_conf (conf_key,conf_value) 
    SELECT 'stripe_testclock', _clock_id;

    REPLACE INTO sys_conf (conf_key,conf_value) 
    SELECT 'stripe_testclock_on', _flag;

    SELECT * from sys_conf WHERE conf_key IN ('stripe_testclock','stripe_testclock_on');

  END $


DELIMITER ;

