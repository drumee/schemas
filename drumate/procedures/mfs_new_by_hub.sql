DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_new_by_hub`$
CREATE PROCEDURE `mfs_new_by_hub`(
  IN _user_id VARCHAR(16),
  IN _since JSON
)
BEGIN
  -- New files and folders per workspace, for the desk rail's Files pill.
  -- The unread base rows of mfs_get_unread_count (same accessible hubs, same
  -- mfs_ack cursor, same mfs_dismissed exclusion, never the user's own), cut
  -- down to what the Files tab shows: media.new only, not workspace creation
  -- (filetype hub), not chat attachments (parent_path /__chat__) nor the trash.
  -- _since = {"<hub_id>": <unix ts>} from the client: per workspace, only
  -- events AFTER the last time the user opened that workspace's Files tab.
  -- Read-only: a user with no mfs_ack row yet gets no rows (mfs_get_unread_count
  -- initialises it), so this never writes.
  DECLARE _last_read_id INT(11) UNSIGNED DEFAULT NULL;
  DECLARE _marks JSON DEFAULT '{}';

  SELECT last_read_id FROM mfs_ack WHERE user_id = _user_id LIMIT 1 INTO _last_read_id;

  IF _since IS NOT NULL AND JSON_VALID(_since) THEN
    SELECT _since INTO _marks;
  END IF;

  IF _last_read_id IS NULL THEN
    SELECT NULL AS hub_id, 0 AS cnt, 0 AS last_ts FROM DUAL WHERE 0;
  ELSE
    DROP TEMPORARY TABLE IF EXISTS _new_by_hub_hubs;
    CREATE TEMPORARY TABLE _new_by_hub_hubs (
      hub_id VARCHAR(16) CHARACTER SET ascii PRIMARY KEY
    );

    INSERT IGNORE INTO _new_by_hub_hubs (hub_id)
    SELECT id FROM yp.hub WHERE owner_id = _user_id AND id IS NOT NULL;

    INSERT IGNORE INTO _new_by_hub_hubs (hub_id)
    SELECT entity_id
    FROM permission
    WHERE resource_id = _user_id
      AND expiry_time > UNIX_TIMESTAMP();

    SELECT
      c.hub_id,
      COUNT(*) AS cnt,
      MAX(c.timestamp) AS last_ts
    FROM yp.mfs_changelog c
    INNER JOIN _new_by_hub_hubs h ON c.hub_id = h.hub_id
    LEFT JOIN mfs_dismissed dm
      ON dm.changelog_id = c.id AND dm.user_id = _user_id
    WHERE c.id > _last_read_id
      AND c.event = 'media.new'
      AND c.uid != _user_id
      AND dm.changelog_id IS NULL
      AND IFNULL(JSON_VALUE(c.src, '$.filetype'), '') != 'hub'
      AND IFNULL(JSON_VALUE(c.src, '$.parent_path'), '') NOT LIKE '/\_\_chat\_\_%'
      AND IFNULL(JSON_VALUE(c.src, '$.parent_path'), '') NOT LIKE '/\_\_trash\_\_%'
      AND c.timestamp > IFNULL(JSON_VALUE(_marks, CONCAT('$."', c.hub_id, '"')), 0)
    GROUP BY c.hub_id;

    DROP TEMPORARY TABLE IF EXISTS _new_by_hub_hubs;
  END IF;
END$

DELIMITER ;
