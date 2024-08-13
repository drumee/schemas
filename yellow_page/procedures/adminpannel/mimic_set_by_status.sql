DELIMITER $



DROP PROCEDURE IF EXISTS `mimic_set_by_status`$
CREATE PROCEDURE `mimic_set_by_status`(
  IN _mimic_id VARCHAR(16),
  IN _option  varchar(10)
 )
BEGIN
 

  IF _option != 'endbytime' THEN

    UPDATE mimic SET status = _option  WHERE id = _mimic_id;
    UPDATE mimic SET metadata=JSON_MERGE(IFNULL(metadata, '{}'), JSON_OBJECT(_option,  UNIX_TIMESTAMP()))
    WHERE id=_mimic_id;

    IF _option = 'active' THEN 
      UPDATE mimic SET estimatetime= (UNIX_TIMESTAMP() + (60*1)) WHERE id = _mimic_id;
    END IF ; 

  ELSE  
   -- INSERT INTO testlog SELECT UNIX_TIMESTAMP(), estimatetime from  mimic where id = _mimic_id ;
    UPDATE mimic SET status = _option  WHERE id = _mimic_id AND estimatetime<=UNIX_TIMESTAMP();
    UPDATE mimic SET metadata=JSON_MERGE(IFNULL(metadata, '{}'), JSON_OBJECT(_option,  UNIX_TIMESTAMP()))
    WHERE id=_mimic_id AND estimatetime<= UNIX_TIMESTAMP();
  END IF ;

  SELECT 
    id _mimic_id ,uid,mimicker,status,metadata,estimatetime 
  FROM 
   mimic 
  WHERE 
    id = _mimic_id;

END $


DELIMITER ;