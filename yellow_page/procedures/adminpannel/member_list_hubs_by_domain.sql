DELIMITER $

DROP PROCEDURE IF EXISTS `member_list_hubs_by_domain`$
CREATE PROCEDURE `member_list_hubs_by_domain`(
  IN _dom_id INT
)
BEGIN
  -- `name` resolved like member_list_workspaces (ident → hub.name → hubname)
  -- so the audit aggregator can attach a display name to each hub's rows.
  SELECT
    e.id,
    e.db_name,
    IFNULL(IFNULL(e.ident, h.name), h.hubname) AS name
  FROM entity e
  LEFT JOIN hub h ON h.id = e.id
  WHERE
    e.dom_id = _dom_id AND
    e.type = 'hub' AND
    e.status = 'active';
END $

DELIMITER ;
