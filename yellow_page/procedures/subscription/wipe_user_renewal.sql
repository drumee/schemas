DELIMITER $




  DROP PROCEDURE IF EXISTS `wipe_user_renewal`$
  CREATE PROCEDURE `wipe_user_renewal`(
    IN _id VARCHAR(16)
    )
  BEGIN
    DELETE  FROM yp.renewal WHERE entity_id = _id;

  END $

DELIMITER ;

