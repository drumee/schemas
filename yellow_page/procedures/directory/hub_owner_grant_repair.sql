DELIMITER $

DROP PROCEDURE IF EXISTS `hub_owner_grant_repair`$
CREATE PROCEDURE `hub_owner_grant_repair`(
  IN _apply TINYINT(1)
)
BEGIN
  -- Give every workspace owner back their access to their own workspace.
  --
  -- desk_create_hub grants it on both sides:
  --   hub DB      permission_grant('*',    owner, 0, 63, 'system', '')
  --   drumate DB  permission_grant(hub_id, owner, 0, 63, 'system', '')
  -- and every hub-scoped service resolves privilege from those rows. Where
  -- they are missing the owner is locked out of their own workspace:
  -- hub.invite (src 'admin', bit 16) answers PERMISSION_DENIED and the client
  -- shows an empty body with no reason -- which is how this was found on
  -- 2026-08-11.
  --
  -- Measured before repair: 7 of 566 active workspaces on stage, 2 of 5197 on
  -- production. Both sides were missing in every case. The most recent
  -- affected workspace was created 2026-05-27, i.e. before the 2026-07-02
  -- dual-write fix; nothing created since is affected, so this is historical
  -- residue rather than an active regression. permission_revoke now refuses
  -- to delete these rows, so the state cannot be re-entered through that door.
  --
  -- _apply = 0 REPORTS what it would do and writes nothing; 1 repairs.
  -- Idempotent either way: a workspace whose owner already holds the grant is
  -- skipped, so re-running is a no-op. Uses permission_grant rather than a
  -- raw INSERT so the row is written exactly the way creation writes it.

  DECLARE _done INT DEFAULT 0;
  DECLARE _hub_id VARCHAR(16);
  DECLARE _owner_id VARCHAR(16);
  DECLARE _hub_db VARCHAR(255);
  DECLARE _owner_db VARCHAR(255);
  DECLARE _has INT DEFAULT 0;
  DECLARE _fixed INT DEFAULT 0;
  DECLARE _seen INT DEFAULT 0;

  DECLARE cur CURSOR FOR
    SELECT h.id, h.owner_id, e.db_name, od.db_name
    FROM yp.hub h
    INNER JOIN yp.entity e  ON e.id = h.id
    LEFT  JOIN yp.entity od ON od.id = h.owner_id
    WHERE e.type = 'hub'
      AND e.status = 'active'
      AND e.db_name IS NOT NULL AND e.db_name != ''
      AND h.owner_id IS NOT NULL AND h.owner_id != ''
      AND h.owner_id != '*';

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _done = 1;
  -- One unreachable workspace database must not abandon the rest.
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

  DROP TEMPORARY TABLE IF EXISTS _owner_grant_repair;
  CREATE TEMPORARY TABLE _owner_grant_repair (
    hub_id   VARCHAR(16),
    owner_id VARCHAR(16),
    hub_db   VARCHAR(255),
    owner_db VARCHAR(255),
    repaired TINYINT(1) NOT NULL DEFAULT 0
  );

  OPEN cur;
  hub_loop: LOOP
    FETCH cur INTO _hub_id, _owner_id, _hub_db, _owner_db;
    IF _done = 1 THEN
      LEAVE hub_loop;
    END IF;

    SET _has = 0;
    SET @s = CONCAT(
      'SELECT COUNT(*) INTO @has FROM `', _hub_db, '`.permission ',
      'WHERE entity_id = ', QUOTE(_owner_id), " AND resource_id = '*' AND permission > 0"
    );
    SET @has = 0;
    PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;
    SET _has = IFNULL(@has, 0);

    IF _has = 0 THEN
      SET _seen = _seen + 1;
      INSERT INTO _owner_grant_repair (hub_id, owner_id, hub_db, owner_db, repaired)
      VALUES (_hub_id, _owner_id, _hub_db, _owner_db, _apply);

      IF _apply = 1 THEN
        -- Hub side: the workspace-wide grant.
        SET @s = CONCAT(
          'CALL `', _hub_db, "`.permission_grant('*', ", QUOTE(_owner_id),
          ", 0, 63, 'system', '')"
        );
        PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

        -- Member side: the owner's own view of the workspace. Skipped when the
        -- owner has no database (a deleted account still named as owner) --
        -- there is nowhere to write, and the hub side above is what the ACL
        -- reads.
        IF _owner_db IS NOT NULL AND _owner_db != '' THEN
          SET @s = CONCAT(
            'CALL `', _owner_db, '`.permission_grant(', QUOTE(_hub_id), ', ',
            QUOTE(_owner_id), ", 0, 63, 'system', '')"
          );
          PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;
        END IF;

        SET _fixed = _fixed + 1;
      END IF;
    END IF;
  END LOOP hub_loop;
  CLOSE cur;

  SELECT _seen AS workspaces_without_owner_grant, _fixed AS repaired;
  SELECT hub_id, owner_id, hub_db, owner_db, repaired FROM _owner_grant_repair;
  DROP TEMPORARY TABLE IF EXISTS _owner_grant_repair;
END $

DELIMITER ;
