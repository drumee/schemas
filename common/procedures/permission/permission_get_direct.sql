DELIMITER $

DROP PROCEDURE IF EXISTS `permission_get_direct`$
CREATE PROCEDURE `permission_get_direct`(
  IN _rid VARCHAR(16),
  IN _eid VARCHAR(16)
)
BEGIN
  -- Return the DIRECTLY stored permission row for an entity on a resource
  -- (resource_id, entity_id) — NOT the effective/inherited privilege that
  -- user_permission() computes. Lets a caller distinguish WHY an entity has
  -- access: a row whose message marks it as a secure-share recipient grant vs
  -- a standing membership / collaborator grant. (resource_id, entity_id) is the
  -- table's unique key, so this is a single indexed lookup.
  SELECT permission, message, assign_via
    FROM permission WHERE resource_id=_rid AND entity_id=_eid LIMIT 1;
END$

DELIMITER ;
