DELIMITER $

DROP PROCEDURE IF EXISTS `contact_assignment_get`$
CREATE PROCEDURE `contact_assignment_get`(
  IN _uid VARCHAR(16)
)
BEGIN
 
  SELECT s.* FROM contact_sync s INNER JOIN drumate d on d.id = s.uid WHERE owner_id = _uid AND status <> 'delete';
END$

DELIMITER ;