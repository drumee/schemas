DELIMITER $

--  to reactive the subscription
  DROP PROCEDURE IF EXISTS `renewal_active`$
  CREATE PROCEDURE `renewal_active`(
    IN _entity_id VARCHAR(16) CHARACTER SET ascii
    )
  BEGIN
    UPDATE renewal SET cancel_time = null
    WHERE entity_id = _entity_id;

    SELECT * from renewal WHERE entity_id = _entity_id;
  END $


DELIMITER ;

