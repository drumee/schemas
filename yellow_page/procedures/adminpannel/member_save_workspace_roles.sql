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
  DECLARE _hub_db VARCHAR(80);
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

  OPEN cur;
  assign_loop: LOOP
    FETCH cur INTO _hub_id, _priv_val;
    IF done THEN LEAVE assign_loop; END IF;

    SELECT db_name INTO _hub_db
    FROM yp.entity
    WHERE id = _hub_id;

    IF _hub_db IS NOT NULL THEN
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
    END IF;
  END LOOP;
  CLOSE cur;

  SELECT 0 AS failed;
END$

DELIMITER ;