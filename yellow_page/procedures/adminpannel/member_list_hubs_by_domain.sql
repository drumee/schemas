DELIMITER $

DROP PROCEDURE IF EXISTS `member_list_hubs_by_domain`$
CREATE PROCEDURE `member_list_hubs_by_domain`(
  IN _dom_id INT
)
BEGIN
  SELECT e.id, e.db_name
  FROM entity e
  WHERE
    e.dom_id = _dom_id AND
    e.type = 'hub' AND
    e.status = 'active';
END $

DELIMITER ;