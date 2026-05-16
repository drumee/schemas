-- File: schemas/yellow_page/procedures/activity_publish.sql
-- Purpose: Generic notification creation under the activity.* namespace.
-- Routes by `_category` to the right underlying table so future system
-- integrations can publish notifications without knowing which audit log
-- they belong to. Most categories already have dedicated paths
-- (chat.post / channel.post / contact.invite_send / media.new write to
-- their own tables); this proc only handles the gap cases.

DELIMITER $

DROP PROCEDURE IF EXISTS `activity_publish`$

CREATE PROCEDURE `activity_publish`(
  IN _category VARCHAR(16),
  IN _author_uid VARCHAR(16),
  IN _key_id VARCHAR(255),
  IN _hub_id VARCHAR(16),
  IN _payload TEXT
)
BEGIN
  DECLARE _now INT(11) UNSIGNED;
  SELECT UNIX_TIMESTAMP() INTO _now;

  CASE
    WHEN _category = 'media' THEN
      -- Insert a generic mfs_changelog row. `_key_id` is the nid of the
      -- file/folder; `_payload` is JSON {event, src, dest, ...}.
      INSERT INTO yp.mfs_changelog (timestamp, uid, hub_id, event, src, dest)
      VALUES (
        _now,
        _author_uid,
        _hub_id,
        IFNULL(JSON_VALUE(_payload, '$.event'), 'media.new'),
        IFNULL(JSON_QUERY(_payload, '$.src'), JSON_OBJECT('nid', _key_id)),
        IFNULL(JSON_QUERY(_payload, '$.dest'), JSON_OBJECT())
      );
      SELECT 'ok' AS status, 'media' AS category, LAST_INSERT_ID() AS id;

    WHEN _category IN ('hub_invite', 'contact_invite') THEN
      -- _key_id = recipient drumate id, _payload carries hub_id / message etc.
      INSERT INTO yp.contact_activity (timestamp, uid, target_uid, event, data)
      VALUES (
        _now,
        _author_uid,
        _key_id,
        IF(_category = 'hub_invite', 'hub_invite_received', 'invite_received'),
        _payload
      );
      SELECT 'ok' AS status, _category AS category, LAST_INSERT_ID() AS id;

    ELSE
      -- chat / teamchat / ticket are produced exclusively by their domain
      -- endpoints (chat.post, channel.post, ticket.post). Do NOT duplicate
      -- writes here; report 'unsupported' so callers route through those.
      SELECT 'unsupported' AS status, _category AS category;
  END CASE;
END$

DELIMITER ;
