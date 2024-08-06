 
DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_check_consistency`$
CREATE PROCEDURE `mfs_check_consistency`(
)
BEGIN
 UPDATE media m LEFT JOIN yp.entity e USING(id) 
   SET m.status= 'orphaned' WHERE category='hub' AND e.id IS NULL;
 DELETE FROM media WHERE STATUS = 'orphaned';

END$