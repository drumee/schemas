DELIMITER $


DROP PROCEDURE IF EXISTS `mimic_new`$
CREATE PROCEDURE `mimic_new`(
  IN _uid  VARCHAR(16) ,
  IN _mimcker  VARCHAR(16) 
 )
BEGIN
  DECLARE _mimic_id VARCHAR(16);

  SELECT yp.uniqueId()  INTO   _mimic_id;  
  INSERT INTO mimic(id,uid,mimicker,status) SELECT  _mimic_id ,  _uid, _mimcker, 'new';
  UPDATE mimic SET metadata=JSON_MERGE(IFNULL(metadata, '{}'), JSON_OBJECT('new',  UNIX_TIMESTAMP()))
  WHERE id=_mimic_id;
  CALL mimic_get(_mimic_id );

END $



DELIMITER ;