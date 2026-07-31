-- Unread cross-workspace move events for the sidebar badge.
--
-- The feed itself reads yp.mfs_changelog directly. This small companion query
-- contributes those events to activity.list, whose result powers the sidebar
-- unread counter. It deliberately keeps the existing event-time visibility
-- model: a recipient sees events from workspaces they can currently access.

DELIMITER $

DROP PROCEDURE IF EXISTS `notification_workspace_moves`$

CREATE PROCEDURE `notification_workspace_moves`()
BEGIN
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _last_read_id INT(11) UNSIGNED DEFAULT 0;

  SELECT id INTO _uid FROM yp.entity WHERE db_name = DATABASE();

  SELECT IFNULL(last_read_id, 0) INTO _last_read_id
  FROM mfs_ack
  WHERE user_id = _uid;

  SELECT
    'workspace_move' AS category,
    c.id AS key_id,
    c.hub_id,
    JSON_VALUE(c.src, '$.nid') AS nid,
    JSON_VALUE(c.src, '$.parent_id') AS parent_id,
    JSON_VALUE(c.src, '$.filename') AS filename,
    JSON_VALUE(c.src, '$.filetype') AS filetype,
    c.id AS last_id,
    c.timestamp AS ctime,
    c.event,
    d.firstname,
    d.lastname,
    d.email,
    c.src,
    c.dest
  FROM yp.mfs_changelog c
  LEFT JOIN yp.drumate d ON d.id = c.uid
  LEFT JOIN mfs_dismissed dm
    ON dm.changelog_id = c.id
   AND dm.user_id = _uid
  WHERE c.event = 'media.workspace_move'
    AND c.uid <> _uid
    AND c.id > _last_read_id
    AND dm.changelog_id IS NULL
    AND (
      EXISTS (
        SELECT 1
        FROM yp.hub h
        WHERE h.id = c.hub_id
          AND h.owner_id = _uid
      )
      OR EXISTS (
        SELECT 1
        FROM permission p
        WHERE p.resource_id = c.hub_id
          AND p.entity_id = _uid
          AND (p.expiry_time = 0 OR p.expiry_time > UNIX_TIMESTAMP())
      )
    )
  ORDER BY c.id DESC;
END$

DELIMITER ;
