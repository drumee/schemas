DELIMITER $

DROP PROCEDURE IF EXISTS `activity_get_feed_all`$

CREATE PROCEDURE `activity_get_feed_all`(
  IN _user_id VARCHAR(16),
  IN _page INT
)
BEGIN
  DECLARE _last_read_id INT(11) UNSIGNED DEFAULT 0;
  DECLARE _offset BIGINT;
  DECLARE _range BIGINT;

  CALL pageToLimits(_page, _offset, _range);

  SELECT IFNULL(last_read_id, 0) INTO _last_read_id
  FROM mfs_ack
  WHERE user_id = _user_id;

  DROP TABLE IF EXISTS _user_accessible_hubs;
  CREATE TEMPORARY TABLE _user_accessible_hubs (
    hub_id VARCHAR(16) CHARACTER SET ascii PRIMARY KEY
  );

  -- id IS NOT NULL: a FAILED workspace creation leaves a yp.hub row with
  -- owner_id set but id still NULL, and _user_accessible_hubs.hub_id is a
  -- PRIMARY KEY (implicitly NOT NULL) under STRICT_TRANS_TABLES. Without this
  -- guard ONE such row makes the whole procedure die with
  -- ERROR 1048 "Column 'hub_id' cannot be null" -- which silently emptied the
  -- notification feed and killed desk search for every affected user.
  -- The two INSERTs below have always been INSERT IGNORE; only this one was
  -- left unguarded.
  INSERT INTO _user_accessible_hubs (hub_id)
  SELECT id FROM yp.hub WHERE owner_id = _user_id AND id IS NOT NULL;

  -- NOTE: `permission` is the per-user drumate-DB table (resolved against the
  -- current DB), NOT yp.permission (which does not exist). Matches the working
  -- mfs_get_activity_feed. The repo's activity_get_log.sql has a stale
  -- `yp.permission` here that the deployed copy does not — do not copy it.
  INSERT IGNORE INTO _user_accessible_hubs (hub_id)
  SELECT entity_id
  FROM permission
  WHERE resource_id = _user_id
    AND expiry_time > UNIX_TIMESTAMP();

  INSERT IGNORE INTO _user_accessible_hubs (hub_id)
  VALUES (_user_id);

  DROP TABLE IF EXISTS _unified_activity;
  CREATE TEMPORARY TABLE _unified_activity (
    id INT(11) UNSIGNED,
    timestamp INT(11) UNSIGNED,
    uid VARCHAR(16) CHARACTER SET ascii,
    event VARCHAR(100),
    event_type VARCHAR(20),
    priority INT,
    src JSON,
    dest JSON,
    data JSON,
    is_read TINYINT,
    firstname VARCHAR(100),
    lastname VARCHAR(100),
    fullname VARCHAR(200),
    hub_id VARCHAR(16) CHARACTER SET ascii,
    hub_db_name VARCHAR(255),
    category VARCHAR(16),
    key_id VARCHAR(255),
    last_id BIGINT,
    history_id BIGINT UNSIGNED,
    KEY idx_priority_time (priority, timestamp)
  );

  -- Contact events: include read + unread history, but exclude rows explicitly
  -- removed from Activity. dismissed_at remains the compatible read marker;
  -- hidden_at is the independent Trash/Delete-all marker.
  INSERT INTO _unified_activity (
    id, timestamp, uid, event, event_type, priority,
    src, dest, data, is_read,
    firstname, lastname, fullname,
    hub_id, hub_db_name, category, key_id, last_id, history_id
  )
  SELECT
    c.id,
    c.timestamp,
    c.uid,
    c.event,
    'contact' AS event_type,
    1 AS priority,
    JSON_OBJECT(
      'uid', c.uid,
      'email', d1.email,
      'fullname', d1.fullname
    ) AS src,
    JSON_OBJECT(
      'uid', c.target_uid,
      'email', d2.email,
      'fullname', d2.fullname
    ) AS dest,
    c.data,
    IF(c.dismissed_at IS NULL, 0, 1) AS is_read,
    d1.firstname,
    d1.lastname,
    d1.fullname,
    NULL AS hub_id,
    NULL AS hub_db_name,
    NULL AS category,
    NULL AS key_id,
    NULL AS last_id,
    NULL AS history_id
  FROM yp.contact_activity c
  LEFT JOIN yp.drumate d1 ON c.uid = d1.id
  LEFT JOIN yp.drumate d2 ON c.target_uid = d2.id
  WHERE c.target_uid = _user_id
    AND c.uid != _user_id
    AND c.hidden_at IS NULL;

  -- MFS events: include BOTH read and unread, and READ IS NOT DELETED.
  --
  -- mfs_dismissed carries BOTH actions and `deleted` is what separates them --
  -- its own column comment says so: "1 = removed by the trash button, never
  -- shown again". Opening a row calls mfs_dismiss_activity, which writes
  -- deleted = 0; the trash button calls mfs_delete_activity, which writes
  -- deleted = 1. Excluding every row present in that table therefore hid the
  -- ones the user had merely READ, which is exactly the behaviour Lexis asked
  -- to stop on 2026-08-28 ("reading a notification must no longer make it
  -- vanish"). Measured on one account: 18 rows read, 0 deleted, all 18 gone.
  --
  -- This mirrors the CONTACT branch above, which has always had it right:
  -- dismissed_at marks READ and keeps the row (is_read = 1), hidden_at marks
  -- DELETED and removes it. Same two markers, same rule, now on both branches.
  --
  -- is_read must consult dm as well, not just mfs_ack: opening a single row
  -- does not advance the ack pointer, so a row restored by this fix would come
  -- back looking UNREAD and re-inflate the badge. A dm row (deleted = 0) IS the
  -- per-row read marker.
  INSERT INTO _unified_activity (
    id, timestamp, uid, event, event_type, priority,
    src, dest, data, is_read,
    firstname, lastname, fullname,
    hub_id, hub_db_name, category, key_id, last_id, history_id
  )
  SELECT
    m.id,
    m.timestamp,
    m.uid,
    m.event,
    'mfs' AS event_type,
    2 AS priority,
    m.src,
    m.dest,
    NULL AS data,
    IF(m.id > _last_read_id AND dm.changelog_id IS NULL, 0, 1) AS is_read,
    d.firstname,
    d.lastname,
    d.fullname,
    m.hub_id,
    e.db_name AS hub_db_name,
    NULL AS category,
    NULL AS key_id,
    NULL AS last_id,
    NULL AS history_id
  FROM yp.mfs_changelog m
  INNER JOIN _user_accessible_hubs ah ON m.hub_id = ah.hub_id
  LEFT JOIN yp.drumate d ON m.uid = d.id
  LEFT JOIN yp.entity e ON m.hub_id = e.id
  LEFT JOIN mfs_dismissed dm
    ON dm.changelog_id = m.id AND dm.user_id = _user_id
  WHERE m.uid != _user_id
    AND (dm.changelog_id IS NULL OR dm.deleted = 0);

  INSERT INTO _unified_activity (
    id, timestamp, uid, event, event_type, priority,
    src, dest, data, is_read,
    firstname, lastname, fullname,
    hub_id, hub_db_name, category, key_id, last_id, history_id
  )
  SELECT
    h.history_id,
    h.ctime,
    NULL,
    'notification.history',
    'notification_history',
    3,
    NULL,
    NULL,
    NULL,
    1,
    NULL,
    NULL,
    NULL,
    NULLIF(h.hub_id, ''),
    NULL,
    h.category,
    h.notification_key,
    h.last_id,
    h.history_id
  FROM notification_activity_history h
  WHERE h.hidden_at IS NULL;

  SELECT
    id,
    timestamp,
    uid,
    event,
    event_type,
    src,
    dest,
    data,
    is_read,
    firstname,
    lastname,
    fullname,
    hub_id,
    hub_db_name,
    category,
    key_id,
    last_id,
    history_id
  FROM _unified_activity
  -- Strictly latest-first across ALL event types. The old `priority ASC,
  -- timestamp DESC` grouped every contact event (priority 1) above every file
  -- event (priority 2) regardless of time, so a day-old upload showed BELOW a
  -- weeks-old contact invite. The user-facing feed must be chronological; id is
  -- a stable tiebreaker for same-second rows so pagination stays deterministic.
  ORDER BY
    timestamp DESC,
    id DESC
  LIMIT _offset, _range;

  DROP TABLE IF EXISTS _user_accessible_hubs;
  DROP TABLE IF EXISTS _unified_activity;

END$

DELIMITER ;
