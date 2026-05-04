DELIMITER $

DROP PROCEDURE IF EXISTS `hub_member_remove`$
CREATE PROCEDURE `hub_member_remove`(
  IN _uid VARCHAR(16),
  IN _removed_by VARCHAR(16)
)
BEGIN
  DELETE FROM permission
  WHERE entity_id = _uid
    AND resource_id = '*';

  CALL hub_add_action_log(
    _removed_by,
    'removed',
    'member',
    'admin',
    _uid,
    'Member removed from workspace'
  );

  SELECT ROW_COUNT() AS affected;
END$

DELIMITER ;