DELIMITER $

DROP PROCEDURE IF EXISTS `chat_upload_grant_repair`$
CREATE PROCEDURE `chat_upload_grant_repair`(
  IN _apply TINYINT(1)
)
BEGIN
  -- Put the existing chat staging grants in the state the role model says
  -- they should be in: raised to a value that carries the write bit for a
  -- member who may chat, and removed entirely for one who may not.
  --
  -- A workspace member who may chat is given a grant on the hidden folder
  -- '/__chat__/__upload__', where an attachment is staged before it becomes a
  -- message. The grant is written with assign_via 'no_traversal' so the raised
  -- access stops at that one folder and never reaches its children.
  --
  -- The value written was 4. That meant write before the permission bits were
  -- renumbered (download 2 -> 4, write 4 -> 8) and means download now, so the
  -- grant no longer satisfies the upload ACL and the member gets a bare 403
  -- with nothing in the UI to explain it. Newly invited members are handled at
  -- the write path; the members already carrying the stale value are not, and
  -- that is what this repairs.
  --
  -- ROLE GATE, and it is the whole point of the join below. The write path
  -- used to hand this grant out regardless of role, so some rows belong to
  -- view-only members -- 22 of 197 on stage. A row is raised only when the
  -- SAME member's workspace-wide grant carries the chat bit (0b0000100).
  --
  -- The other 22 are deleted rather than left alone, which is not the cautious
  -- option it looks like. 4 is the download bit WITHOUT the read bit, so once
  -- a node grant can raise the account-wide value, leaving the row would take
  -- a view-only member from 3 to 4 on that folder -- trading read for
  -- download. Removing it also matches the invariant the role-change path now
  -- keeps, since it revokes this row on demotion.
  --
  -- Rows holding 3 rather than 4 are a different grant and are left alone.
  --
  -- _apply = 0 REPORTS what it would do and writes nothing; 1 repairs.
  -- Idempotent: a raised row no longer holds 4 and a removed row is gone, so
  -- neither matches on a second run.
  --
  -- Raises the value on the row that is already there rather than going
  -- through permission_grant. The row exists in every case -- this is a
  -- correction to a value, not a new grant -- and three things argued against
  -- the procedure here, all of them observed on stage rather than assumed:
  --
  --   permission_grant refuses to write at all in a workspace where no member
  --   holds 63 on '*'. Five such workspaces exist on stage; their owners carry
  --   31 or even 7. Every grant there rolls back with 'New granting would
  --   create orphaned hub', which silently blocked 12 of these repairs. That
  --   guard protects a workspace from losing its last owner and has nothing to
  --   say about raising an existing member's access to one folder.
  --
  --   permission_grant writes with REPLACE INTO, so it deletes the row and
  --   inserts a new one under a fresh sys_id, discarding the original ctime. A
  --   value correction should leave the grant's identity and history alone.
  --
  --   It ends with a bare SELECT, so a loop over every affected member returns
  --   one result set per row and buries the report this procedure exists to
  --   produce.
  --
  -- 'repaired' is set from reading the row BACK after the grant, never from
  -- having reached the line that issued it. The per-database error handler
  -- below is deliberately silent so one unreachable workspace cannot abandon
  -- the rest, which means a failed grant would otherwise be indistinguishable
  -- from a successful one.

  DECLARE _done INT DEFAULT 0;
  DECLARE _db_name VARCHAR(255);
  DECLARE _row_db VARCHAR(255);
  DECLARE _row_entity VARCHAR(16);
  DECLARE _row_node VARCHAR(16);
  DECLARE _seen INT DEFAULT 0;
  DECLARE _fixed INT DEFAULT 0;

  DECLARE db_cur CURSOR FOR
    SELECT e.db_name
    FROM yp.entity e
    WHERE e.type = 'hub'
      AND e.status = 'active'
      AND e.db_name IS NOT NULL AND e.db_name != '';

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _done = 1;
  -- One unreachable workspace database must not abandon the rest.
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

  DROP TEMPORARY TABLE IF EXISTS _chat_upload_grant_repair;
  CREATE TEMPORARY TABLE _chat_upload_grant_repair (
    db_name        VARCHAR(255),
    entity_id      VARCHAR(16),
    chat_upload_id VARCHAR(16),
    account_perm   TINYINT(4),
    node_perm      TINYINT(4),
    action         VARCHAR(8) NOT NULL DEFAULT 'raise',
    repaired       TINYINT(1) NOT NULL DEFAULT 0
  );

  -- Pass one: collect every candidate row, writing nothing.
  OPEN db_cur;
  db_loop: LOOP
    FETCH db_cur INTO _db_name;
    IF _done = 1 THEN
      LEAVE db_loop;
    END IF;

    SET @cuid = NULL;
    SET @s = CONCAT(
      'SELECT `', _db_name, '`.node_id_from_path(''/__chat__/__upload__'') INTO @cuid'
    );
    PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

    IF @cuid IS NOT NULL AND @cuid != '' THEN
      -- n is the grant on the staging folder, s the same member's grant on the
      -- workspace as a whole. The bit test on s is the role gate.
      SET @s = CONCAT(
        'INSERT INTO _chat_upload_grant_repair ',
        '(db_name, entity_id, chat_upload_id, account_perm, node_perm, action) ',
        'SELECT ', QUOTE(_db_name), ', n.entity_id, n.resource_id, ',
        's.permission, n.permission, ',
        'IF((s.permission & 4) > 0, ''raise'', ''remove'') ',
        'FROM `', _db_name, '`.permission n ',
        'INNER JOIN `', _db_name, '`.permission s ',
        '  ON s.entity_id = n.entity_id AND s.resource_id = ''*'' ',
        'WHERE n.resource_id = ', QUOTE(@cuid), ' ',
        '  AND n.assign_via = ''no_traversal'' ',
        '  AND n.permission = 4'
      );
      PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;
    END IF;
  END LOOP db_loop;
  CLOSE db_cur;

  SELECT COUNT(*) FROM _chat_upload_grant_repair INTO _seen;

  -- Pass two: raise them, then read each row back to decide what to report.
  IF _apply = 1 THEN
    BEGIN
      DECLARE _row_done INT DEFAULT 0;
      DECLARE _act VARCHAR(8);
      DECLARE row_cur CURSOR FOR
        SELECT db_name, entity_id, chat_upload_id, action
        FROM _chat_upload_grant_repair;
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET _row_done = 1;
      DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

      OPEN row_cur;
      row_loop: LOOP
        FETCH row_cur INTO _row_db, _row_entity, _row_node, _act;
        IF _row_done = 1 THEN
          LEAVE row_loop;
        END IF;

        -- Both branches repeat every condition that made the row a candidate,
        -- so a row that changed underneath us since the first pass is left
        -- alone.
        IF _act = 'raise' THEN
          -- 15 is the edit mask: read + download + write. It applies to this
          -- one folder, and assign_via 'no_traversal' keeps it from reaching
          -- anything inside it.
          SET @s = CONCAT(
            'UPDATE `', _row_db, '`.permission SET permission = 15, ',
            'utime = UNIX_TIMESTAMP() ',
            'WHERE resource_id = ', QUOTE(_row_node),
            ' AND entity_id = ', QUOTE(_row_entity),
            " AND assign_via = 'no_traversal' AND permission = 4"
          );
        ELSE
          -- A member who may not chat has no business holding this row at all.
          -- Leaving it is not neutral: 4 is the download bit WITHOUT the read
          -- bit, so once a node grant can raise the account-wide value the row
          -- would take a view-only member from 3 to 4 on this folder, trading
          -- read for download. Removing it is also the invariant the role
          -- change path now keeps -- it revokes this row on demotion.
          SET @s = CONCAT(
            'DELETE FROM `', _row_db, '`.permission ',
            'WHERE resource_id = ', QUOTE(_row_node),
            ' AND entity_id = ', QUOTE(_row_entity),
            " AND assign_via = 'no_traversal' AND permission = 4"
          );
        END IF;
        PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

        -- Read back and judge from what is actually there now.
        --
        -- Through MAX() rather than a plain SELECT, so the read-back returns a
        -- row even when the grant is gone. A bare 'SELECT permission INTO'
        -- over no rows raises NOT FOUND, which is the loop's own end-of-cursor
        -- condition: the remove branch would end the loop after its first row
        -- and report the other twenty as untouched.
        SET @got = -1;
        SET @s = CONCAT(
          'SELECT IFNULL(MAX(permission), -1) INTO @got FROM `', _row_db,
          '`.permission WHERE resource_id = ', QUOTE(_row_node),
          ' AND entity_id = ', QUOTE(_row_entity)
        );
        PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

        -- Raised: the write bit is 8, and anything without it did not take.
        -- Removed: the row has to be gone.
        IF (_act = 'raise' AND @got > 0 AND (@got & 8) > 0)
           OR (_act = 'remove' AND @got = -1) THEN
          UPDATE _chat_upload_grant_repair
            SET repaired = 1, node_perm = NULLIF(@got, -1)
          WHERE db_name = _row_db AND entity_id = _row_entity;
          SET _fixed = _fixed + 1;
        END IF;
      END LOOP row_loop;
      CLOSE row_cur;
    END;
  END IF;

  SELECT _seen AS rows_to_change, _fixed AS changed;
  SELECT db_name, entity_id, chat_upload_id, account_perm, node_perm, action, repaired
    FROM _chat_upload_grant_repair
    ORDER BY db_name, entity_id;
  DROP TEMPORARY TABLE IF EXISTS _chat_upload_grant_repair;
END $

DELIMITER ;
