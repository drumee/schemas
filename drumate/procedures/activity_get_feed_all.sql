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

  INSERT INTO _user_accessible_hubs (hub_id)
  SELECT id FROM yp.hub WHERE owner_id = _user_id;

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
    KEY idx_priority_time (priority, timestamp)
  );

  -- Contact events: include BOTH read and unread (unlike activity_get_log,
  -- which filters dismissed_at IS NULL). A contact event is unread until it
  -- is dismissed (mark_all_read / dismiss_contact_event both set dismissed_at),
  -- so is_read is driven solely by dismissed_at here.
  INSERT INTO _unified_activity (
    id, timestamp, uid, event, event_type, priority,
    src, dest, data, is_read,
    firstname, lastname, fullname,
    hub_id, hub_db_name
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
    NULL AS hub_db_name
  FROM yp.contact_activity c
  LEFT JOIN yp.drumate d1 ON c.uid = d1.id
  LEFT JOIN yp.drumate d2 ON c.target_uid = d2.id
  WHERE (c.uid = _user_id OR c.target_uid = _user_id)
    AND c.uid != _user_id;

  -- MFS events: include BOTH read and unread (unlike activity_get_log, which
  -- filters m.id > _last_read_id AND not dismissed). An MFS event is unread
  -- until the read pointer passes it OR the user dismisses it; either makes it
  -- read. The mfs_dismissed LEFT JOIN is kept solely to compute is_read.
  INSERT INTO _unified_activity (
    id, timestamp, uid, event, event_type, priority,
    src, dest, data, is_read,
    firstname, lastname, fullname,
    hub_id, hub_db_name
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
    e.db_name AS hub_db_name
  FROM yp.mfs_changelog m
  INNER JOIN _user_accessible_hubs ah ON m.hub_id = ah.hub_id
  LEFT JOIN yp.drumate d ON m.uid = d.id
  LEFT JOIN yp.entity e ON m.hub_id = e.id
  LEFT JOIN mfs_dismissed dm
    ON dm.changelog_id = m.id AND dm.user_id = _user_id
  WHERE m.uid != _user_id;

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
    hub_db_name
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
