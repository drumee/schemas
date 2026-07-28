DELIMITER $

-- =========================================================
-- channel_migrate_moved_scope
-- Migrates folder-scoped `channel` rows + per-file `file_thread` rows to the
-- DESTINATION hub/drumate db (this proc runs in dest's schema context — call
-- via `CALL <dest_db>.channel_migrate_moved_scope(...)`) when mfs_move_all
-- moves a subtree cross-hub. Failure-isolated by design: mfs_move_all is not
-- transactional (mfs_create_node self-COMMITs, source media rows are already
-- DELETEd by the time this runs) so a migrate error here must NEVER abort the
-- caller. Every internal step is wrapped in its own CONTINUE HANDLER FOR
-- SQLEXCEPTION that absorbs the error into `channel_migrate_log` and lets the
-- remaining steps proceed independently.
--
-- Emits NO result set (INSERT/UPDATE/DELETE + SELECT...INTO only) — the
-- caller's `_final_media` result-set contract (parsed by 3 consumers) must be
-- the only rowset mfs_move_all returns.
--
-- Params:
--   _src_db        source hub/drumate db name (identifier, from yp.entity)
--   _src_hub_id    source hub/drumate entity id (for logging)
--   _dest_hub_id   destination entity id == _recipient_id (for logging)
--   _uid           acting user id
--   _mapping       JSON array of the node id remap produced by mfs_move_all's
--                  cross-hub copy loop for the CURRENT top-level node:
--                  [{"id":old_nid,"new_id":new_nid,"category":cat,
--                    "new_parent_id":new_parent_nid}, ...]
--                  Only rows with a non-null new_id are meaningful.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_migrate_moved_scope`$
CREATE PROCEDURE `channel_migrate_moved_scope`(
  IN _src_db VARCHAR(50),
  IN _src_hub_id VARCHAR(16),
  IN _dest_hub_id VARCHAR(16),
  IN _uid VARCHAR(16),
  IN _mapping JSON
)
proc_body: BEGIN
  DECLARE _now INT(11) UNSIGNED;

  -- Schema probes (F2 / constraint #3): a DB that hasn't received the
  -- file_thread DDL patch yet must no-op the thread-specific steps but still
  -- run the folder-scoped chat migration.
  DECLARE _dest_has_entity_id   INT DEFAULT 0;
  DECLARE _src_has_entity_id    INT DEFAULT 0;
  DECLARE _src_has_ft_col       INT DEFAULT 0;
  DECLARE _dest_has_ft_col      INT DEFAULT 0;
  DECLARE _src_has_ft_tbl       INT DEFAULT 0;
  DECLARE _dest_has_ft_tbl      INT DEFAULT 0;
  DECLARE _thread_infra_ok      INT DEFAULT 0;
  DECLARE _dest_rc_has_entity_id INT DEFAULT 0;

  DECLARE _map_idx INT DEFAULT 0;
  DECLARE _map_len INT DEFAULT 0;
  DECLARE _map_node JSON;
  DECLARE _map_old VARCHAR(16) CHARACTER SET ascii;
  DECLARE _map_new VARCHAR(16) CHARACTER SET ascii;
  DECLARE _map_cat VARCHAR(50);
  DECLARE _map_new_parent VARCHAR(16) CHARACTER SET ascii;

  DECLARE _f9_done INT DEFAULT 0;
  DECLARE _f9_message_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _f9_file_nid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _f9_current_parent VARCHAR(16) CHARACTER SET ascii;
  DECLARE _f9_count INT DEFAULT 0;

  DECLARE _rw_done INT DEFAULT 0;
  DECLARE _rw_message_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _rw_attachment JSON;
  DECLARE _rw_len INT;
  DECLARE _rw_idx INT;
  DECLARE _rw_entry JSON;
  DECLARE _rw_nid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _rw_new_nid VARCHAR(16) CHARACTER SET ascii;

  SET _now = UNIX_TIMESTAMP();

  IF _mapping IS NULL OR JSON_VALID(_mapping) = 0 OR JSON_LENGTH(_mapping) = 0 THEN
    LEAVE proc_body;
  END IF;

  -- ---------------------------------------------------------------------
  -- Step 1: probe schema (both sides) — absorbed individually so a probe
  -- failure degrades to "treat as missing" rather than killing the call.
  -- ---------------------------------------------------------------------
  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
      GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
      INSERT INTO channel_migrate_log (src_hub_id, dest_hub_id, uid, stage, detail, ctime)
      VALUES (_src_hub_id, _dest_hub_id, _uid, 'probe_schema',
        CONCAT('[', @sqlstate, ':', @errno, '] ', @text), _now);
    END;

    SELECT COUNT(*) INTO _dest_has_entity_id FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'channel' AND COLUMN_NAME = 'entity_id';
    SELECT COUNT(*) INTO _dest_has_ft_col FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'channel' AND COLUMN_NAME = 'file_thread_id';
    SELECT COUNT(*) INTO _dest_has_ft_tbl FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'file_thread';
    SELECT COUNT(*) INTO _dest_rc_has_entity_id FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'read_channel' AND COLUMN_NAME = 'entity_id';

    SELECT COUNT(*) INTO _src_has_entity_id FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = _src_db AND TABLE_NAME = 'channel' AND COLUMN_NAME = 'entity_id';
    SELECT COUNT(*) INTO _src_has_ft_col FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = _src_db AND TABLE_NAME = 'channel' AND COLUMN_NAME = 'file_thread_id';
    SELECT COUNT(*) INTO _src_has_ft_tbl FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = _src_db AND TABLE_NAME = 'file_thread';
  END;

  SET _thread_infra_ok = IF(_src_has_ft_tbl = 1 AND _dest_has_ft_tbl = 1 AND _dest_has_ft_col = 1, 1, 0);
  IF _thread_infra_ok = 0 THEN
    INSERT INTO channel_migrate_log (src_hub_id, dest_hub_id, uid, stage, detail, ctime)
    VALUES (_src_hub_id, _dest_hub_id, _uid, 'thread_infra_missing',
      CONCAT('src_ft_tbl=', _src_has_ft_tbl, ' dest_ft_tbl=', _dest_has_ft_tbl, ' dest_ft_col=', _dest_has_ft_col),
      _now);
  END IF;

  -- ---------------------------------------------------------------------
  -- Working temp tables (session-local — safe to reuse across CALLs since
  -- each CALL starts with DROP/CREATE).
  -- ---------------------------------------------------------------------
  DROP TABLE IF EXISTS `_migrate_map`;
  CREATE TEMPORARY TABLE `_migrate_map` (
    `old_id` VARCHAR(16) CHARACTER SET ascii NOT NULL,
    `new_id` VARCHAR(16) CHARACTER SET ascii DEFAULT NULL,
    `category` VARCHAR(50) DEFAULT NULL,
    `new_parent_id` VARCHAR(16) CHARACTER SET ascii DEFAULT NULL,
    PRIMARY KEY (`old_id`)
  ) ENGINE=InnoDB;

  DROP TABLE IF EXISTS `_migrate_src_rows`;
  CREATE TEMPORARY TABLE `_migrate_src_rows` (
    `seq` INT NOT NULL AUTO_INCREMENT,
    `old_message_id` VARCHAR(16) CHARACTER SET ascii NOT NULL,
    `new_message_id` VARCHAR(16) CHARACTER SET ascii DEFAULT NULL,
    `author_id` VARCHAR(16) CHARACTER SET ascii DEFAULT NULL,
    `message` MEDIUMTEXT,
    `thread_id` VARCHAR(16) CHARACTER SET ascii DEFAULT NULL,
    `old_file_thread_id` VARCHAR(16) CHARACTER SET ascii DEFAULT NULL,
    `attachment` LONGTEXT,
    `is_forward` TINYINT(1) DEFAULT 0,
    `entity_id` VARCHAR(16) CHARACTER SET ascii DEFAULT NULL,
    `status` VARCHAR(20) DEFAULT NULL,
    `ctime` INT(11) UNSIGNED DEFAULT NULL,
    `metadata` MEDIUMTEXT,
    `new_scope_nid` VARCHAR(16) CHARACTER SET ascii DEFAULT NULL,
    `row_kind` VARCHAR(20) DEFAULT NULL,
    `src_sys_id` BIGINT UNSIGNED DEFAULT NULL,
    PRIMARY KEY (`seq`),
    KEY `old_message_id` (`old_message_id`)
  ) ENGINE=InnoDB;

  DROP TABLE IF EXISTS `_migrate_src_file_thread`;
  CREATE TEMPORARY TABLE `_migrate_src_file_thread` (
    `old_file_nid` VARCHAR(16) CHARACTER SET ascii NOT NULL,
    `old_root_message_id` VARCHAR(16) CHARACTER SET ascii DEFAULT NULL,
    `created_by` VARCHAR(16) CHARACTER SET ascii DEFAULT NULL,
    `old_last_message_id` VARCHAR(16) CHARACTER SET ascii DEFAULT NULL,
    `reply_count` INT(11) UNSIGNED DEFAULT 0,
    `ctime` INT(11) DEFAULT NULL,
    `mtime` INT(11) DEFAULT NULL,
    `status` VARCHAR(20) DEFAULT NULL,
    PRIMARY KEY (`old_file_nid`)
  ) ENGINE=InnoDB;

  DROP TABLE IF EXISTS `_id_remap`;
  CREATE TEMPORARY TABLE `_id_remap` (
    `old_id` VARCHAR(16) CHARACTER SET ascii NOT NULL,
    `new_id` VARCHAR(16) CHARACTER SET ascii NOT NULL,
    PRIMARY KEY (`old_id`)
  ) ENGINE=InnoDB;

  -- ---------------------------------------------------------------------
  -- Step 2a: materialize the node id map (JSON param -> local temp table).
  -- ---------------------------------------------------------------------
  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
      GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
      INSERT INTO channel_migrate_log (src_hub_id, dest_hub_id, uid, stage, detail, ctime)
      VALUES (_src_hub_id, _dest_hub_id, _uid, 'build_migrate_map',
        CONCAT('[', @sqlstate, ':', @errno, '] ', @text), _now);
    END;

    SET _map_len = JSON_LENGTH(_mapping);
    SET _map_idx = 0;
    WHILE _map_idx < _map_len DO
      SELECT JSON_EXTRACT(_mapping, CONCAT('$[', _map_idx, ']')) INTO _map_node;
      SELECT JSON_VALUE(_map_node, '$.id') INTO _map_old;
      SELECT JSON_VALUE(_map_node, '$.new_id') INTO _map_new;
      SELECT JSON_VALUE(_map_node, '$.category') INTO _map_cat;
      SELECT JSON_VALUE(_map_node, '$.new_parent_id') INTO _map_new_parent;
      IF _map_old IS NOT NULL AND _map_new IS NOT NULL THEN
        INSERT IGNORE INTO _migrate_map (old_id, new_id, category, new_parent_id)
        VALUES (_map_old, _map_new, _map_cat, _map_new_parent);
      END IF;
      SET _map_idx = _map_idx + 1;
    END WHILE;
  END;

  -- ---------------------------------------------------------------------
  -- Step 2b (Architecture #2/#3): capture folder-scoped normal messages —
  -- metadata._scope_nid matches a moved node, not a thread child, not a
  -- file-thread root card. ORDER BY sys_id ASC preserves send order under
  -- the new AUTO_INCREMENT. JSON guard on every read.
  -- ---------------------------------------------------------------------
  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
      GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
      INSERT INTO channel_migrate_log (src_hub_id, dest_hub_id, uid, stage, detail, ctime)
      VALUES (_src_hub_id, _dest_hub_id, _uid, 'capture_folder_scoped',
        CONCAT('[', @sqlstate, ':', @errno, '] ', @text), _now);
    END;

    SET @sql = CONCAT(
      'INSERT INTO _migrate_src_rows ',
      '(old_message_id, author_id, message, thread_id, old_file_thread_id, attachment, is_forward, ',
      IF(_src_has_entity_id = 1, 'entity_id, ', ''),
      'status, ctime, metadata, new_scope_nid, row_kind, src_sys_id) ',
      'SELECT c.message_id, c.author_id, c.message, c.thread_id, NULL, c.attachment, c.is_forward, ',
      IF(_src_has_entity_id = 1, 'c.entity_id, ', ''),
      'c.status, c.ctime, c.metadata, mm.new_id, ''folder_msg'', c.sys_id ',
      'FROM ', _src_db, '.channel c ',
      'INNER JOIN _migrate_map mm ON mm.old_id = JSON_VALUE(c.metadata, ''$._scope_nid'') ',
      'WHERE c.metadata IS NOT NULL AND JSON_VALID(c.metadata) = 1 ',
      IF(_src_has_ft_col = 1, 'AND c.file_thread_id IS NULL ', ''),
      'AND IFNULL(JSON_VALUE(c.metadata, ''$._file_thread_root''), ''0'') <> ''1'' ',
      'ORDER BY c.sys_id ASC'
    );
    PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
  END;

  -- ---------------------------------------------------------------------
  -- Step 2c (Architecture #4): file-thread root cards + children, only when
  -- both DBs have the file_thread schema.
  -- C4: root cards are keyed on the FILE (`_file_nid`) being IN
  -- _migrate_map — the folder itself does NOT need to be in the map. A
  -- single-file cross-hub move (AC3) moves only the file; its parent folder
  -- stays at src, so `mm` (folder map) is now a LEFT JOIN — when the folder
  -- didn't move, `new_scope_nid` falls back to the file's `new_parent_id`
  -- (fm.new_parent_id, the file's new parent at dest = the folder it lives
  -- under there), otherwise (folder moved too) it uses the folder's own
  -- new_id (mm.new_id) so the card scopes under the migrated folder like any
  -- other row. Files moved OUT of subtree earlier are F9, handled below and
  -- never touched here (guarded by requiring fm.old_id = _file_nid to exist,
  -- which F9's predicate — file NOT in map — excludes by construction).
  -- ---------------------------------------------------------------------
  IF _thread_infra_ok = 1 THEN
    BEGIN
      DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
      BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
        INSERT INTO channel_migrate_log (src_hub_id, dest_hub_id, uid, stage, detail, ctime)
        VALUES (_src_hub_id, _dest_hub_id, _uid, 'capture_thread_root',
          CONCAT('[', @sqlstate, ':', @errno, '] ', @text), _now);
      END;

      SET @sql = CONCAT(
        'INSERT INTO _migrate_src_rows ',
        '(old_message_id, author_id, message, thread_id, old_file_thread_id, attachment, is_forward, ',
        IF(_src_has_entity_id = 1, 'entity_id, ', ''),
        'status, ctime, metadata, new_scope_nid, row_kind, src_sys_id) ',
        'SELECT c.message_id, c.author_id, c.message, c.thread_id, NULL, c.attachment, c.is_forward, ',
        IF(_src_has_entity_id = 1, 'c.entity_id, ', ''),
        'c.status, c.ctime, c.metadata, COALESCE(mm.new_id, fm.new_parent_id), ''thread_root'', c.sys_id ',
        'FROM ', _src_db, '.channel c ',
        'INNER JOIN _migrate_map fm ON fm.old_id = JSON_VALUE(c.metadata, ''$._file_nid'') ',
        'LEFT JOIN _migrate_map mm ON mm.old_id = JSON_VALUE(c.metadata, ''$._scope_nid'') ',
        'WHERE c.metadata IS NOT NULL AND JSON_VALID(c.metadata) = 1 ',
        'AND IFNULL(JSON_VALUE(c.metadata, ''$._file_thread_root''), ''0'') = ''1'' ',
        'ORDER BY c.sys_id ASC'
      );
      PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
    END;

    BEGIN
      DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
      BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
        INSERT INTO channel_migrate_log (src_hub_id, dest_hub_id, uid, stage, detail, ctime)
        VALUES (_src_hub_id, _dest_hub_id, _uid, 'capture_thread_children',
          CONCAT('[', @sqlstate, ':', @errno, '] ', @text), _now);
      END;

      -- Children of ANY root card we just captured (root ids now in
      -- _migrate_src_rows). M4: JSON_VALID guard added (a malformed child
      -- row must not fail the whole batch/Step-4 INSERT).
      SET @sql = CONCAT(
        'INSERT INTO _migrate_src_rows ',
        '(old_message_id, author_id, message, thread_id, old_file_thread_id, attachment, is_forward, ',
        IF(_src_has_entity_id = 1, 'entity_id, ', ''),
        'status, ctime, metadata, new_scope_nid, row_kind, src_sys_id) ',
        'SELECT c.message_id, c.author_id, c.message, c.thread_id, c.file_thread_id, c.attachment, c.is_forward, ',
        IF(_src_has_entity_id = 1, 'c.entity_id, ', ''),
        'c.status, c.ctime, c.metadata, r.new_scope_nid, ''thread_child'', c.sys_id ',
        'FROM ', _src_db, '.channel c ',
        'INNER JOIN _migrate_src_rows r ON r.old_message_id = c.file_thread_id AND r.row_kind = ''thread_root'' ',
        'WHERE c.file_thread_id IS NOT NULL ',
        'AND (c.metadata IS NULL OR JSON_VALID(c.metadata) = 1) ',
        'ORDER BY c.sys_id ASC'
      );
      PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
    END;

    -- Snapshot the file_thread rows themselves for the files being migrated.
    BEGIN
      DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
      BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
        INSERT INTO channel_migrate_log (src_hub_id, dest_hub_id, uid, stage, detail, ctime)
        VALUES (_src_hub_id, _dest_hub_id, _uid, 'capture_file_thread_rows',
          CONCAT('[', @sqlstate, ':', @errno, '] ', @text), _now);
      END;

      SET @sql = CONCAT(
        'INSERT INTO _migrate_src_file_thread ',
        '(old_file_nid, old_root_message_id, created_by, old_last_message_id, reply_count, ctime, mtime, status) ',
        'SELECT ft.file_nid, ft.root_message_id, ft.created_by, ft.last_message_id, ft.reply_count, ft.ctime, ft.mtime, ft.status ',
        'FROM ', _src_db, '.file_thread ft ',
        'INNER JOIN _migrate_map mm ON mm.old_id = ft.file_nid ',
        'ORDER BY ft.sys_id ASC'
      );
      PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
    END;
  END IF;

  -- ---------------------------------------------------------------------
  -- Step 3 (constraint #5): collision absorb-remap. Pre-check NOT EXISTS in
  -- dest; remint via yp.uniqueId() and record the map. One defensive retry
  -- pass covers the astronomically-rare case the freshly minted id itself
  -- collides (yp.uniqueId() is NOT collision-proof cross-DB).
  -- ---------------------------------------------------------------------
  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
      GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
      INSERT INTO channel_migrate_log (src_hub_id, dest_hub_id, uid, stage, detail, ctime)
      VALUES (_src_hub_id, _dest_hub_id, _uid, 'collision_remap',
        CONCAT('[', @sqlstate, ':', @errno, '] ', @text), _now);
    END;

    INSERT INTO _id_remap (old_id, new_id)
    SELECT DISTINCT r.old_message_id, yp.uniqueId()
    FROM _migrate_src_rows r
    WHERE EXISTS (SELECT 1 FROM channel c WHERE c.message_id = r.old_message_id);

    -- Defensive retry: regenerate any freshly-minted id that itself collides.
    UPDATE _id_remap m
    SET m.new_id = yp.uniqueId()
    WHERE EXISTS (SELECT 1 FROM channel c WHERE c.message_id = m.new_id);

    UPDATE _migrate_src_rows r
    LEFT JOIN _id_remap m ON m.old_id = r.old_message_id
    SET r.new_message_id = COALESCE(m.new_id, r.old_message_id);

    IF ROW_COUNT() > 0 THEN
      INSERT INTO channel_migrate_log (src_hub_id, dest_hub_id, uid, stage, detail, ctime)
      SELECT _src_hub_id, _dest_hub_id, _uid, 'collision_remap',
        CONCAT('remapped old=', old_id, ' new=', new_id), _now
      FROM _id_remap;
    END IF;
  END;

  -- ---------------------------------------------------------------------
  -- Step 4 (Architecture #3/#4): copy transformed rows into dest `channel`.
  -- Explicit columns (constraint #10) — hub/drumate shape differ (entity_id);
  -- `file_thread_id` column itself is conditional on _dest_has_ft_col (C3) —
  -- a dest without the file_thread DDL must still receive folder-scoped chat
  -- rows, it just cannot carry a file_thread_id value. Column list built via
  -- CONCAT (identifiers/static fragments only, no user values — F13); values
  -- still flow through the SELECT, never string-interpolated.
  -- Q1: strip _seen_/_delivered_/_reactions_, mention_ids -> NULL.
  -- _scope_nid rewritten to new folder id; thread_id / file_thread_id remapped
  -- via _id_remap with COALESCE (C2) — `_id_remap` only holds ids that
  -- COLLIDED at dest; the common no-collision path must keep the original id
  -- (thread_id already did; file_thread_id now matches).
  -- ---------------------------------------------------------------------
  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
      GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
      INSERT INTO channel_migrate_log (src_hub_id, dest_hub_id, uid, stage, detail, ctime)
      VALUES (_src_hub_id, _dest_hub_id, _uid, 'insert_dest_channel',
        CONCAT('[', @sqlstate, ':', @errno, '] ', @text), _now);
    END;

    SET @sql = CONCAT(
      'INSERT INTO channel (message_id, author_id, message, thread_id, ',
      IF(_dest_has_ft_col = 1, 'file_thread_id, ', ''),
      'attachment, is_forward, mention_ids, ',
      IF(_dest_has_entity_id = 1, 'entity_id, ', ''),
      'status, ctime, metadata) ',
      'SELECT r.new_message_id, r.author_id, r.message, COALESCE(tremap.new_id, r.thread_id), ',
      IF(_dest_has_ft_col = 1, 'COALESCE(ftremap.new_id, r.old_file_thread_id), ', ''),
      'r.attachment, r.is_forward, NULL, ',
      IF(_dest_has_entity_id = 1, 'r.entity_id, ', ''),
      'r.status, r.ctime, ',
      'JSON_REMOVE(COALESCE(r.metadata, JSON_OBJECT()), ''$._seen_'', ''$._delivered_'', ''$._reactions_'') ',
      'FROM _migrate_src_rows r ',
      'LEFT JOIN _id_remap tremap ON tremap.old_id = r.thread_id ',
      IF(_dest_has_ft_col = 1, 'LEFT JOIN _id_remap ftremap ON ftremap.old_id = r.old_file_thread_id ', ''),
      'ORDER BY r.src_sys_id ASC, r.seq ASC' -- M1: global sys_id order across folder_msg/thread_root/thread_child batches
    );
    PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

    -- metadata._scope_nid -> new folder id (always present on migrated rows).
    UPDATE channel c
    INNER JOIN _migrate_src_rows r ON r.new_message_id = c.message_id
    SET c.metadata = JSON_SET(c.metadata, '$._scope_nid', r.new_scope_nid)
    WHERE r.new_scope_nid IS NOT NULL;

    -- metadata._file_thread_id -> remapped root id (root card self-refs its
    -- own new id; children resolve via the same _id_remap keyed on old root).
    UPDATE channel c
    INNER JOIN _migrate_src_rows r ON r.new_message_id = c.message_id
    INNER JOIN _id_remap ftm ON ftm.old_id = COALESCE(r.old_file_thread_id, JSON_VALUE(r.metadata, '$._file_thread_id'))
    SET c.metadata = JSON_SET(c.metadata, '$._file_thread_id', ftm.new_id)
    WHERE JSON_VALUE(r.metadata, '$._file_thread_id') IS NOT NULL;

    -- metadata._file_nid -> remapped file id (root/child cards only).
    UPDATE channel c
    INNER JOIN _migrate_src_rows r ON r.new_message_id = c.message_id
    INNER JOIN _migrate_map fm ON fm.old_id = JSON_VALUE(r.metadata, '$._file_nid')
    SET c.metadata = JSON_SET(c.metadata, '$._file_nid', fm.new_id)
    WHERE JSON_VALUE(r.metadata, '$._file_nid') IS NOT NULL;
  END;

  -- ---------------------------------------------------------------------
  -- Step 4b (Q2/H1): rewrite attachment[] entries whose `folder_nid` matches
  -- a moved node — folder-promoted attachments are
  -- {hub_id, nid: <sbox copy>, folder_nid: <folder file>} per
  -- server-team/channel.js:256-292; the sbox copy (`nid`) does NOT move
  -- cross-hub (lives in the hub's own chat storage, outside the subtree) —
  -- only `folder_nid` (the real subtree file, IS in _migrate_map) is what
  -- reply-in-thread / View-Chat-Threads resolve, so only it is rewritten
  -- (+ hub_id). Plain-string entries (no folder_nid key) are left untouched —
  -- no concrete shape requires rewriting bare `nid` and doing so risks
  -- mislabeling hub_id on bits that never moved. Purely local (dest-only)
  -- after the insert above, so no dynamic SQL is needed here.
  -- ---------------------------------------------------------------------
  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
      GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
      INSERT INTO channel_migrate_log (src_hub_id, dest_hub_id, uid, stage, detail, ctime)
      VALUES (_src_hub_id, _dest_hub_id, _uid, 'rewrite_attachment',
        CONCAT('[', @sqlstate, ':', @errno, '] ', @text), _now);
    END;

    BEGIN
      DECLARE rw_cursor CURSOR FOR
        SELECT c.message_id, c.attachment FROM channel c
        INNER JOIN _migrate_src_rows r ON r.new_message_id = c.message_id
        WHERE c.attachment IS NOT NULL AND JSON_VALID(c.attachment) = 1;
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET _rw_done = 1;

      OPEN rw_cursor;
      rw_loop: LOOP
        FETCH rw_cursor INTO _rw_message_id, _rw_attachment;
        IF _rw_done = 1 THEN LEAVE rw_loop; END IF;

        SET _rw_len = JSON_LENGTH(_rw_attachment);
        SET _rw_idx = 0;
        WHILE _rw_idx < _rw_len DO
          SET _rw_entry = NULL;
          SET _rw_nid = NULL;
          SET _rw_new_nid = NULL;
          SELECT JSON_EXTRACT(_rw_attachment, CONCAT('$[', _rw_idx, ']')) INTO _rw_entry;
          SELECT JSON_VALUE(_rw_entry, '$.folder_nid') INTO _rw_nid;

          IF _rw_nid IS NOT NULL THEN
            -- H2: pre-null + MAX() aggregate — no NOT FOUND, no stale value.
            SELECT MAX(new_id) FROM _migrate_map WHERE old_id = _rw_nid INTO _rw_new_nid;
            IF _rw_new_nid IS NOT NULL THEN
              -- Only folder_nid moves with the folder. hub_id pairs with `nid`,
              -- the sender's sbox copy that stays in the source hub — rewriting
              -- it would point attachment resolution at a hub that has no such
              -- node, breaking downloads for every viewer.
              SELECT JSON_SET(_rw_attachment,
                CONCAT('$[', _rw_idx, '].folder_nid'), _rw_new_nid) INTO _rw_attachment;
            END IF;
          END IF;
          SET _rw_idx = _rw_idx + 1;
        END WHILE;

        UPDATE channel SET attachment = _rw_attachment WHERE message_id = _rw_message_id;
      END LOOP;
      CLOSE rw_cursor;
    END;
  END;

  -- ---------------------------------------------------------------------
  -- Step 5 (Architecture #4): copy `file_thread` rows into dest.
  -- C2: rootmap/lastmap COALESCE — `_id_remap` only holds collided ids; the
  -- common no-collision path must keep the original root_message_id/
  -- last_message_id (both NOT NULL/UNIQUE on file_thread — missing COALESCE
  -- previously nulled them out and errored the whole INSERT under STRICT
  -- mode, failing every cross-hub thread migration).
  -- ---------------------------------------------------------------------
  IF _thread_infra_ok = 1 THEN
    BEGIN
      DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
      BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
        INSERT INTO channel_migrate_log (src_hub_id, dest_hub_id, uid, stage, detail, ctime)
        VALUES (_src_hub_id, _dest_hub_id, _uid, 'insert_dest_file_thread',
          CONCAT('[', @sqlstate, ':', @errno, '] ', @text), _now);
      END;

      INSERT INTO file_thread (
        file_nid, folder_nid, root_message_id, created_by, last_message_id,
        reply_count, ctime, mtime, status
      )
      SELECT
        fm.new_id,
        fm.new_parent_id,
        COALESCE(rootmap.new_id, ft.old_root_message_id),
        ft.created_by,
        COALESCE(lastmap.new_id, ft.old_last_message_id),
        ft.reply_count, ft.ctime, ft.mtime, ft.status
      FROM _migrate_src_file_thread ft
      INNER JOIN _migrate_map fm ON fm.old_id = ft.old_file_nid
      LEFT JOIN _id_remap rootmap ON rootmap.old_id = ft.old_root_message_id
      LEFT JOIN _id_remap lastmap ON lastmap.old_id = ft.old_last_message_id
      ORDER BY ft.old_file_nid ASC;
    END;
  END IF;

  -- ---------------------------------------------------------------------
  -- Step 6 (F9): root cards whose file is OUTSIDE this move's mapping (file
  -- was relocated within src before this move) — stay in src, re-scope to
  -- the file's CURRENT parent_id there. Never captured/deleted above (the
  -- capture query in step 2c requires the file to be IN _migrate_map).
  -- ---------------------------------------------------------------------
  IF _thread_infra_ok = 1 THEN
    BEGIN
      DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
      BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
        INSERT INTO channel_migrate_log (src_hub_id, dest_hub_id, uid, stage, detail, ctime)
        VALUES (_src_hub_id, _dest_hub_id, _uid, 'f9_rescope',
          CONCAT('[', @sqlstate, ':', @errno, '] ', @text), _now);
      END;

      DROP TABLE IF EXISTS `_f9_orphans`;
      CREATE TEMPORARY TABLE `_f9_orphans` (
        message_id VARCHAR(16) CHARACTER SET ascii,
        file_nid VARCHAR(16) CHARACTER SET ascii,
        PRIMARY KEY (message_id)
      ) ENGINE=InnoDB;

      SET @sql = CONCAT(
        'INSERT INTO _f9_orphans (message_id, file_nid) ',
        'SELECT c.message_id, JSON_VALUE(c.metadata, ''$._file_nid'') ',
        'FROM ', _src_db, '.channel c ',
        'INNER JOIN _migrate_map mm ON mm.old_id = JSON_VALUE(c.metadata, ''$._scope_nid'') ',
        'WHERE c.metadata IS NOT NULL AND JSON_VALID(c.metadata) = 1 ',
        'AND IFNULL(JSON_VALUE(c.metadata, ''$._file_thread_root''), ''0'') = ''1'' ',
        'AND JSON_VALUE(c.metadata, ''$._file_nid'') IS NOT NULL ',
        'AND NOT EXISTS (SELECT 1 FROM _migrate_map fm WHERE fm.old_id = JSON_VALUE(c.metadata, ''$._file_nid''))'
      );
      PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

      SET _f9_done = 0;
      SET _f9_count = 0;
      BEGIN
        DECLARE f9_cursor CURSOR FOR SELECT message_id, file_nid FROM _f9_orphans;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET _f9_done = 1;

        OPEN f9_cursor;
        f9_loop: LOOP
          FETCH f9_cursor INTO _f9_message_id, _f9_file_nid;
          IF _f9_done = 1 THEN LEAVE f9_loop; END IF;

          -- H2: MAX() aggregate always returns exactly one row (never NOT
          -- FOUND) even when _f9_file_nid no longer exists in src media —
          -- a plain SELECT...INTO here would trip the cursor's shared NOT
          -- FOUND handler and silently truncate the remaining f9 loop.
          SET @_f9_parent = NULL;
          SET @sql2 = CONCAT('SELECT MAX(parent_id) FROM ', _src_db, '.media WHERE id = ? INTO @_f9_parent');
          PREPARE stmt2 FROM @sql2;
          EXECUTE stmt2 USING _f9_file_nid;
          DEALLOCATE PREPARE stmt2;
          SELECT @_f9_parent INTO _f9_current_parent;

          IF _f9_current_parent IS NOT NULL THEN
            SET @sql3 = CONCAT(
              'UPDATE ', _src_db, '.channel SET metadata = JSON_SET(metadata, ''$._scope_nid'', ?) WHERE message_id = ?'
            );
            PREPARE stmt3 FROM @sql3;
            EXECUTE stmt3 USING _f9_current_parent, _f9_message_id;
            DEALLOCATE PREPARE stmt3;

            SET @sql4 = CONCAT(
              'UPDATE ', _src_db, '.file_thread SET folder_nid = ? WHERE file_nid = ?'
            );
            PREPARE stmt4 FROM @sql4;
            EXECUTE stmt4 USING _f9_current_parent, _f9_file_nid;
            DEALLOCATE PREPARE stmt4;

            SET _f9_count = _f9_count + 1;
          END IF;
        END LOOP;
        CLOSE f9_cursor;
      END;

      IF _f9_count > 0 THEN
        INSERT INTO channel_migrate_log (src_hub_id, dest_hub_id, uid, stage, detail, ctime)
        VALUES (_src_hub_id, _dest_hub_id, _uid, 'f9_rescope',
          CONCAT('rescoped_count=', _f9_count), _now);
      END IF;
    END;
  END IF;

  -- ---------------------------------------------------------------------
  -- Step 7 (Q3): seed dest members' read_channel watermark up to the max
  -- sys_id among rows just migrated, so historical migrated messages don't
  -- badge-storm. Conditional UPDATE keeps this idempotent (F6).
  -- M3: drumate `read_channel` is UNIQUE(entity_id, uid) with an `entity_id`
  -- column (probed above, _dest_rc_has_entity_id) — without it, NULL never
  -- matches the unique key and ON DUPLICATE never fires, accumulating junk
  -- rows every migration. Per Q3 (plan-conform, flagged M3/Q3 in review):
  -- this intentionally also marks any pre-existing unread dest messages up
  -- to the migrated watermark as read — accepted trade-off, not a bug here.
  -- ---------------------------------------------------------------------
  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
      GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
      INSERT INTO channel_migrate_log (src_hub_id, dest_hub_id, uid, stage, detail, ctime)
      VALUES (_src_hub_id, _dest_hub_id, _uid, 'seed_watermark',
        CONCAT('[', @sqlstate, ':', @errno, '] ', @text), _now);
    END;

    SELECT MAX(c.sys_id) FROM channel c
      INNER JOIN _migrate_src_rows r ON r.new_message_id = c.message_id
      INTO @_watermark_sys_id;

    IF @_watermark_sys_id IS NOT NULL THEN
      IF _dest_rc_has_entity_id = 1 THEN
        INSERT INTO read_channel (entity_id, uid, ref_sys_id, ctime)
        SELECT p.entity_id, p.entity_id, @_watermark_sys_id, _now
        FROM permission p
        WHERE p.resource_id = '*' AND p.entity_id <> _uid
        ON DUPLICATE KEY UPDATE
          ref_sys_id = IF(read_channel.ref_sys_id < @_watermark_sys_id, @_watermark_sys_id, read_channel.ref_sys_id),
          ctime = IF(read_channel.ref_sys_id < @_watermark_sys_id, _now, read_channel.ctime);
      ELSE
        INSERT INTO read_channel (uid, ref_sys_id, ctime)
        SELECT p.entity_id, @_watermark_sys_id, _now
        FROM permission p
        WHERE p.resource_id = '*' AND p.entity_id <> _uid
        ON DUPLICATE KEY UPDATE
          ref_sys_id = IF(read_channel.ref_sys_id < @_watermark_sys_id, @_watermark_sys_id, read_channel.ref_sys_id),
          ctime = IF(read_channel.ref_sys_id < @_watermark_sys_id, _now, read_channel.ctime);
      END IF;
    END IF;
  END;

  -- ---------------------------------------------------------------------
  -- Step 8 (F3/C1): capture-then-delete. A src row is only ever deleted when
  -- a verified copy exists at dest — join `_migrate_src_rows`/
  -- `_migrate_src_file_thread` to the ACTUAL dest table on the new id,
  -- never a bare snapshot-driven delete. This is what makes Step-4's
  -- CONTINUE handler safe: if the dest INSERT was absorbed (error, missing
  -- column per C3, bad JSON per M4), zero dest rows exist, the join finds
  -- nothing, and the delete removes nothing — src stays intact, migration
  -- failure degrades to "not migrated" rather than "message lost".
  -- Never re-derive the _scope_nid predicate here (a post landing mid-
  -- migration would otherwise be deleted without ever having been copied).
  -- ---------------------------------------------------------------------
  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
      GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
      INSERT INTO channel_migrate_log (src_hub_id, dest_hub_id, uid, stage, detail, ctime)
      VALUES (_src_hub_id, _dest_hub_id, _uid, 'capture_then_delete',
        CONCAT('[', @sqlstate, ':', @errno, '] ', @text), _now);
    END;

    SET @sql = CONCAT(
      'DELETE c FROM ', _src_db, '.channel c ',
      'INNER JOIN _migrate_src_rows r ON r.old_message_id = c.message_id ',
      'INNER JOIN channel d ON d.message_id = r.new_message_id'
    );
    PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

    -- C1/M5: count captured-but-not-verified rows (dest insert absorbed a
    -- failure) — these stay at src by construction of the DELETE above; log
    -- once so the failure is visible instead of silently "just not there".
    SET @sql = CONCAT(
      'SELECT COUNT(*) FROM ', _src_db, '.channel c ',
      'INNER JOIN _migrate_src_rows r ON r.old_message_id = c.message_id ',
      'INTO @_leftover_unverified'
    );
    PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
    IF @_leftover_unverified > 0 THEN
      INSERT INTO channel_migrate_log (src_hub_id, dest_hub_id, uid, stage, detail, ctime)
      VALUES (_src_hub_id, _dest_hub_id, _uid, 'leftover',
        CONCAT('unverified_channel_rows=', @_leftover_unverified), _now);
    END IF;

    IF _thread_infra_ok = 1 THEN
      SET @sql = CONCAT(
        'DELETE ft FROM ', _src_db, '.file_thread ft ',
        'INNER JOIN _migrate_src_file_thread s ON s.old_file_nid = ft.file_nid ',
        'INNER JOIN _migrate_map fm ON fm.old_id = s.old_file_nid ',
        'INNER JOIN file_thread d ON d.file_nid = fm.new_id'
      );
      PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

      SET @sql = CONCAT(
        'SELECT COUNT(*) FROM ', _src_db, '.file_thread ft ',
        'INNER JOIN _migrate_src_file_thread s ON s.old_file_nid = ft.file_nid ',
        'INTO @_leftover_ft_unverified'
      );
      PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
      IF @_leftover_ft_unverified > 0 THEN
        INSERT INTO channel_migrate_log (src_hub_id, dest_hub_id, uid, stage, detail, ctime)
        VALUES (_src_hub_id, _dest_hub_id, _uid, 'leftover',
          CONCAT('unverified_file_thread_rows=', @_leftover_ft_unverified), _now);
      END IF;
    END IF;

    -- M5 (AC5 log gap): rows that still match a migrated scope but never
    -- made it into the capture snapshot at all (posted after step 2's
    -- capture window, before this delete ran) — correctly stay at src, but
    -- the plan requires a log-row so the count isn't invisible.
    SET @sql = CONCAT(
      'SELECT COUNT(*) FROM ', _src_db, '.channel c ',
      'INNER JOIN _migrate_map mm ON mm.old_id = JSON_VALUE(c.metadata, ''$._scope_nid'') ',
      'WHERE c.metadata IS NOT NULL AND JSON_VALID(c.metadata) = 1 ',
      'AND NOT EXISTS (SELECT 1 FROM _migrate_src_rows r WHERE r.old_message_id = c.message_id) ',
      'INTO @_leftover_orphan'
    );
    PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
    IF @_leftover_orphan > 0 THEN
      INSERT INTO channel_migrate_log (src_hub_id, dest_hub_id, uid, stage, detail, ctime)
      VALUES (_src_hub_id, _dest_hub_id, _uid, 'leftover',
        CONCAT('missed_capture_window_rows=', @_leftover_orphan), _now);
    END IF;
  END;

END proc_body$

DELIMITER ;
