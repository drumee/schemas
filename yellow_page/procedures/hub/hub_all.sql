DELIMITER $



  DROP PROCEDURE IF EXISTS `hub_all`$
  CREATE PROCEDURE `hub_all`(
    IN _uid VARCHAR(16)
    )
  BEGIN

    SELECT  
      h.id,
      home_dir,
      area -- * 
    FROM  
    yp.hub h
    INNER JOIN yp.entity e on e.id = h.id
    WHERE  h.owner_id = _uid;

  END $                                               


DELIMITER ;

