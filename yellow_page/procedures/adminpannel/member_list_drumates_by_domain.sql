DELIMITER $

DROP PROCEDURE IF EXISTS `member_list_drumates_by_domain`$
CREATE PROCEDURE `member_list_drumates_by_domain`(
  IN _dom_id INT
)
BEGIN
  -- Companion to member_list_hubs_by_domain. Returns active drumate (user)
  -- DBs in the domain so admin.get_audit_logs can aggregate audit rows
  -- written into a user's drumate.action_log — needed for events whose
  -- own hub DB has been destroyed (workspace deletion) or that are
  -- naturally cross-hub.
  SELECT e.id, e.db_name
  FROM entity e
  WHERE
    e.dom_id = _dom_id AND
    e.type = 'drumate' AND
    e.status = 'active';
END $

DELIMITER ;
