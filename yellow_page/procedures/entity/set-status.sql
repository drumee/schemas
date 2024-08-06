DELIMITER $


-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `entity_set_status`$
CREATE PROCEDURE `entity_set_status`(
  IN _id          VARCHAR(16),
  IN _status      VARCHAR(30)
)
BEGIN
  UPDATE entity set status=_status where id=_id;
END$


DELIMITER ;
