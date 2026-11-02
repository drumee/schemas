DELIMITER $

-- =========================================================
-- hub_rename_for_members
--
-- Rename a workspace for EVERY member, not just the caller.
--
-- A workspace has no single name on screen: each member's desk carries its
-- own row for it (<member_db>.media, id = hub id, category = 'hub') and the
-- desk lists `user_filename` from that row (mfs_show_node_by). media.rename
-- only ever touched the caller's row, so the other members kept the old name.
--
-- Writes yp.hub.name (the shared name, capped at its 80 chars) and then each
-- member desk row, resolving a clash with that member's own items through
-- their own unique_filename — exactly what mfs_rename does for the caller.
-- A row that already carries the name, or the name plus a "(N)" clash suffix,
-- is left alone (unique_filename would count it as its own clash and answer
-- the next "(N)").
--
-- Members are the drumate entities granted anything in <hub_db>.permission —
-- the same population entity_sockets(hub_id) pushes to. A member with no desk
-- row yet (invitation not accepted) is skipped.
--
-- Returns one row per member: uid, db_name, old_filename, filename, changed.
-- The caller fetches each member's node from THEIR db to build the push.
-- =========================================================
DROP PROCEDURE IF EXISTS `hub_rename_for_members`$
CREATE PROCEDURE `hub_rename_for_members`(
  IN _hub_id VARCHAR(16),
  IN _name VARCHAR(255)
)
BEGIN
  DECLARE _hub_db VARCHAR(255);
  DECLARE _uid VARCHAR(16);
  DECLARE _db VARCHAR(255);
  DECLARE _i INT DEFAULT 0;
  DECLARE _count INT DEFAULT 0;

  SELECT TRIM('/' FROM TRIM(_name)) INTO _name;

  SELECT e.db_name FROM entity e INNER JOIN hub h ON h.id = e.id
    WHERE e.id = _hub_id INTO _hub_db;

  DROP TEMPORARY TABLE IF EXISTS _hub_rename_members;
  CREATE TEMPORARY TABLE _hub_rename_members (
    idx INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    uid VARCHAR(16) CHARACTER SET ascii,
    db_name VARCHAR(255),
    old_filename VARCHAR(1024),
    filename VARCHAR(1024),
    changed TINYINT(1) DEFAULT 0
  );

  IF _hub_db IS NOT NULL AND _name IS NOT NULL AND _name <> '' THEN
    UPDATE hub SET
      `name` = LEFT(_name, 80),
      `profile` = IF(JSON_VALID(`profile`), JSON_SET(`profile`, "$.name", LEFT(_name, 80)), `profile`)
      WHERE id = _hub_id;

    SET @s = CONCAT(
      "INSERT INTO _hub_rename_members (uid, db_name) ",
      "SELECT DISTINCT e.id, e.db_name FROM `", REPLACE(_hub_db, '`', '``'), "`.permission p ",
      "INNER JOIN entity e ON e.id = p.entity_id AND e.type = 'drumate' ",
      "INNER JOIN information_schema.schemata s ON s.schema_name = e.db_name"
    );
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- An indexed walk, not a cursor: a member with no desk row makes the
    -- SELECT ... INTO below find nothing, and a NOT FOUND handler would end
    -- a cursor loop right there for every member after them.
    SELECT COUNT(*) FROM _hub_rename_members INTO _count;
    WHILE _i < _count DO
      SET _i = _i + 1;
      SELECT uid, db_name FROM _hub_rename_members WHERE idx = _i INTO _uid, _db;

      -- ONE MEMBER NEVER BREAKS THE OTHERS. Stage carries desks that predate
      -- unique_filename / filepath; a failure there skips that member (no row
      -- returned, so no push) instead of failing the rename for everyone.
      member: BEGIN
        DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN END;
        SET @old = NULL;
        SET @s = CONCAT(
          "SELECT TRIM('/' FROM user_filename) FROM `", REPLACE(_db, '`', '``'),
          "`.media WHERE id = ? AND category = 'hub' INTO @old"
        );
        PREPARE stmt FROM @s;
        EXECUTE stmt USING _hub_id;
        DEALLOCATE PREPARE stmt;

        IF @old IS NOT NULL THEN
          -- Already this name, or this name plus the "(N)" its own clash gave
          -- it last time: leave it, or every call would walk it up to (N+1).
          IF @old <> _name AND REGEXP_REPLACE(@old, '\\([0-9]+\\)$', '') <> _name THEN
            SET @s = CONCAT(
              "UPDATE `", REPLACE(_db, '`', '``'), "`.media SET ",
              "publish_time = UNIX_TIMESTAMP(), ",
              "user_filename = `", REPLACE(_db, '`', '``'), "`.unique_filename(parent_id, ?, NULL) ",
              "WHERE id = ? AND category = 'hub'"
            );
            PREPARE stmt FROM @s;
            EXECUTE stmt USING _name, _hub_id;
            DEALLOCATE PREPARE stmt;

            SET @s = CONCAT(
              "UPDATE `", REPLACE(_db, '`', '``'), "`.media SET ",
              "parent_path = `", REPLACE(_db, '`', '``'), "`.parent_path(id), ",
              "file_path = `", REPLACE(_db, '`', '``'), "`.filepath(id) ",
              "WHERE id = ?"
            );
            PREPARE stmt FROM @s;
            EXECUTE stmt USING _hub_id;
            DEALLOCATE PREPARE stmt;
          END IF;

          SET @new = NULL;
          SET @s = CONCAT(
            "SELECT TRIM('/' FROM user_filename) FROM `", REPLACE(_db, '`', '``'),
            "`.media WHERE id = ? INTO @new"
          );
          PREPARE stmt FROM @s;
          EXECUTE stmt USING _hub_id;
          DEALLOCATE PREPARE stmt;

          UPDATE _hub_rename_members SET
            old_filename = @old,
            filename = @new,
            changed = IF(@old <> @new, 1, 0)
            WHERE idx = _i;
        END IF;
      END member;
    END WHILE;
  END IF;

  SELECT uid, db_name, old_filename, filename, changed
    FROM _hub_rename_members WHERE filename IS NOT NULL;
  DROP TEMPORARY TABLE IF EXISTS _hub_rename_members;
END $

DELIMITER ;
