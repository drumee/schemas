DELIMITER $

DROP PROCEDURE IF EXISTS `member_save_workspace_roles`$
CREATE PROCEDURE `member_save_workspace_roles`(
  IN _uid VARCHAR(16),
  IN _assignments LONGTEXT
  -- JSON: [{"hub_id":"...","privilege":7}, ...]
)
BEGIN
  DECLARE _hub_id VARCHAR(16);
  DECLARE _priv_val TINYINT(4) UNSIGNED;
  DECLARE _ui_priv  TINYINT(4) UNSIGNED;
  DECLARE _hub_db VARCHAR(80);
  DECLARE _member_db VARCHAR(80);
  DECLARE _ts INT(11) DEFAULT 0;
  DECLARE _stmt TEXT;
  DECLARE done INT DEFAULT FALSE;

  DECLARE cur CURSOR FOR
    SELECT hub_id, privilege
    FROM JSON_TABLE(
      _assignments,
      '$[*]' COLUMNS(
        hub_id VARCHAR(16) PATH '$.hub_id',
        privilege TINYINT(4) UNSIGNED PATH '$.privilege'
      )
    ) AS jt;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  SELECT UNIX_TIMESTAMP() INTO _ts;
  -- The member owns the workspace-list rows. member_list_workspaces reads
  -- `<member_db>`.permission (resource_id = hub_id), NOT the hub-side '*' row —
  -- so a grant that only touches the hub side never shows up in the list.
  SELECT db_name INTO _member_db FROM yp.entity WHERE id = _uid;

  OPEN cur;
  assign_loop: LOOP
    FETCH cur INTO _hub_id, _priv_val;
    IF done THEN LEAVE assign_loop; END IF;

    SELECT db_name INTO _hub_db FROM yp.entity WHERE id = _hub_id;

    IF _hub_db IS NOT NULL AND _member_db IS NOT NULL THEN

      -- (1) Hub side (resource_id='*'). Keep permission_grant so its
      -- orphaned-hub guard (must keep >=1 owner) still protects the hub.
      -- permission_grant signature:
      -- (resource_id, entity_id, expiry_time, permission, assign_via, msg)
      SET _stmt = CONCAT(
        'CALL `', _hub_db, '`.permission_grant(',
          QUOTE('*'), ', ',
          QUOTE(_uid), ', ',
          '0, ',
          _priv_val, ', ',
          QUOTE('system'), ', ',
          QUOTE(''), ')'
      );
      PREPARE s FROM _stmt;
      EXECUTE s;
      DEALLOCATE PREPARE s;

      -- Detect a brand-new membership BEFORE writing the member-side row, so we
      -- only wire the desk node (join_hub) for newly added workspaces and don't
      -- clobber an existing shortcut on a permission-only change.
      SET _stmt = CONCAT(
        'SELECT COUNT(*) INTO @_ws_exists FROM `', _member_db,
        '`.permission WHERE resource_id=', QUOTE(_hub_id),
        ' AND entity_id=', QUOTE(_uid)
      );
      PREPARE s FROM _stmt;
      EXECUTE s;
      DEALLOCATE PREPARE s;

      -- (2) Member side (resource_id=hub_id) — the row member_list_workspaces
      -- reads. add_member stores permission = privilege|15 here; mirror it so the
      -- saved role is reflected in the admin-console workspace list.
      SELECT _priv_val | 15 INTO _ui_priv;
      SET _stmt = CONCAT(
        'REPLACE INTO `', _member_db, '`.permission VALUES(null, ',
          QUOTE(_hub_id), ', ',
          QUOTE(_uid), ', ',
          QUOTE('---'), ', ',
          '0, ',
          _ts, ', ',
          _ts, ', ',
          _ui_priv, ', ',
          QUOTE('share'), ')'
      );
      PREPARE s FROM _stmt;
      EXECUTE s;
      DEALLOCATE PREPARE s;

      -- (3) For a new workspace, mount the hub on the member's desk (idempotent
      -- REPLACE INTO media). Skipped on permission-only changes to preserve any
      -- existing shortcut/rename.
      IF @_ws_exists = 0 THEN
        SET _stmt = CONCAT('CALL `', _member_db, '`.join_hub(', QUOTE(_hub_id), ')');
        PREPARE s FROM _stmt;
        EXECUTE s;
        DEALLOCATE PREPARE s;
      END IF;

    END IF;
  END LOOP;
  CLOSE cur;

  SELECT 0 AS failed;
END$

DELIMITER ;
