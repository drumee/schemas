DELIMITER $



DROP PROCEDURE IF EXISTS `mimic_get`$
CREATE PROCEDURE `mimic_get`(
   IN _mimic_id VARCHAR(16)
 )
BEGIN
  SELECT 
    m.id mimic_id ,
    m.uid,
    m.mimicker,
    m.status,
    m.metadata,
    m.estimatetime,
    CASE WHEN  m.status = 'active' THEN 
    ( m.estimatetime  -  UNIX_TIMESTAMP())  ELSE NULL END remaining_time ,
    dm.firstname mimicker_firstname,
    dm.lastname  mimicker_lastname,
    dm.fullname  mimicker_fullname,
    du.firstname user_firstname,
    du.lastname  user_lastname,
    du.fullname  user_fullname
  FROM 
  mimic m 
  INNER JOIN yp.entity e    ON  m.uid=e.id 
  INNER JOIN yp.drumate dm  ON  m.mimicker=dm.id 
  INNER JOIN yp.drumate du  ON  m.uid=du.id 
  WHERE m.id = _mimic_id;
END$


DELIMITER ;