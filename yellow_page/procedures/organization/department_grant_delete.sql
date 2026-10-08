DELIMITER $

-- =========================================================
-- department_grant_delete
-- =========================================================
-- Forget a department grant once it has been taken back.
DROP PROCEDURE IF EXISTS `department_grant_delete`$
CREATE PROCEDURE `department_grant_delete`(IN _hub_id VARCHAR(16), IN _uid VARCHAR(16))
BEGIN
  DELETE FROM department_grant WHERE hub_id = _hub_id AND uid = _uid;
  SELECT ROW_COUNT() AS deleted;
END$

DELIMITER ;
