DELIMITER $

DROP PROCEDURE IF EXISTS `hub_member_remove`$
CREATE PROCEDURE `hub_member_remove`(
  IN _uid VARCHAR(16),
  IN _removed_by VARCHAR(16)
)
BEGIN
  DECLARE _hid VARCHAR(16);
  DECLARE _member_db VARCHAR(80);

  -- Hub side (current db = hub_db): drop this member's hub-level grant.
  DELETE FROM permission
  WHERE entity_id = _uid
    AND resource_id = '*';

  -- Member side: member_list_workspaces reads `<member_db>`.permission
  -- (resource_id = this hub's id) and the desk node lives in `<member_db>`.media
  -- (id = hub id, created by join_hub). Deleting only the hub-side '*' row leaves
  -- the removed member still listed in the admin-console workspace list — mirror
  -- remove_member's member-side cleanup so removal is reflected everywhere.
  SELECT id FROM yp.entity WHERE db_name = database() INTO _hid;
  SELECT db_name FROM yp.entity WHERE id = _uid INTO _member_db;

  IF _member_db IS NOT NULL AND _hid IS NOT NULL THEN
    SET @s = CONCAT('DELETE FROM `', _member_db,
      '`.permission WHERE resource_id = ', QUOTE(_hid),
      ' AND entity_id = ', QUOTE(_uid));
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET @s = CONCAT('DELETE FROM `', _member_db,
      '`.media WHERE id = ', QUOTE(_hid));
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;

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
