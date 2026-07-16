-- File: schemas/yellow_page/procedures/contact/contact_log_activity.sql
-- Purpose: Log contact activity events to yp.contact_activity table.
-- Idempotent for hub_invite_received, invite_received and task_assigned: skips
-- insertion if an undismissed row already exists for the same (uid, target_uid,
-- event) and same scope inside JSON data (hub_id for hub invites, task_id for
-- task assignments). Keeps the audit log clean when an inviter re-runs
-- add_contributors, re-invites the same contact, or re-assigns the same task.

DELIMITER $

DROP PROCEDURE IF EXISTS `contact_log_activity`$

CREATE PROCEDURE `contact_log_activity`(
  IN _uid VARCHAR(16),           -- User who triggered the action
  IN _target_uid VARCHAR(16),    -- User who receives the action
  IN _event VARCHAR(100),        -- Event type: invite_sent, invite_received, invite_accepted, invite_refused, hub_invite_received
  IN _data JSON
)
BEGIN
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _task_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _col_key VARCHAR(32) CHARACTER SET ascii;
  DECLARE _col_nid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _existing_id BIGINT DEFAULT NULL;

  -- Only log if both users exist (skip email-only invites)
  IF _uid IS NOT NULL AND _uid != '' AND _target_uid IS NOT NULL AND _target_uid != '' THEN

    IF _event = 'hub_invite_received' THEN
      -- Dedupe per (inviter, recipient, hub). Re-invites should refresh the
      -- existing row's timestamp/data instead of stacking new rows.
      SET _hub_id = JSON_UNQUOTE(JSON_EXTRACT(_data, '$.hub_id'));

      SELECT id INTO _existing_id
        FROM yp.contact_activity
       WHERE uid = _uid
         AND target_uid = _target_uid
         AND event = 'hub_invite_received'
         AND JSON_UNQUOTE(JSON_EXTRACT(data, '$.hub_id')) = _hub_id
         AND dismissed_at IS NULL
       ORDER BY id DESC
       LIMIT 1;

      IF _existing_id IS NOT NULL THEN
        UPDATE yp.contact_activity
           SET timestamp = UNIX_TIMESTAMP(),
               data = _data
         WHERE id = _existing_id;
      ELSE
        INSERT INTO yp.contact_activity (timestamp, uid, target_uid, event, data)
        VALUES (UNIX_TIMESTAMP(), _uid, _target_uid, _event, _data);
      END IF;

    ELSEIF _event = 'invite_received' THEN
      -- Dedupe contact invitations per (inviter, recipient).
      SELECT id INTO _existing_id
        FROM yp.contact_activity
       WHERE uid = _uid
         AND target_uid = _target_uid
         AND event = 'invite_received'
         AND dismissed_at IS NULL
       ORDER BY id DESC
       LIMIT 1;

      IF _existing_id IS NOT NULL THEN
        UPDATE yp.contact_activity
           SET timestamp = UNIX_TIMESTAMP(),
               data = _data
         WHERE id = _existing_id;
      ELSE
        INSERT INTO yp.contact_activity (timestamp, uid, target_uid, event, data)
        VALUES (UNIX_TIMESTAMP(), _uid, _target_uid, _event, _data);
      END IF;

    ELSEIF _event = 'task_assigned' THEN
      -- Dedupe per (assigner, assignee, task). Re-assigning the same person to
      -- the same task refreshes the existing undismissed row instead of stacking
      -- new rows. Once the assignee dismisses it, a later re-assignment finds no
      -- undismissed row and inserts a fresh one (a new notification).
      SET _task_id = JSON_UNQUOTE(JSON_EXTRACT(_data, '$.task_id'));

      SELECT id INTO _existing_id
        FROM yp.contact_activity
       WHERE uid = _uid
         AND target_uid = _target_uid
         AND event = 'task_assigned'
         AND JSON_UNQUOTE(JSON_EXTRACT(data, '$.task_id')) = _task_id
         AND dismissed_at IS NULL
       ORDER BY id DESC
       LIMIT 1;

      IF _existing_id IS NOT NULL THEN
        UPDATE yp.contact_activity
           SET timestamp = UNIX_TIMESTAMP(),
               data = _data
         WHERE id = _existing_id;
      ELSE
        INSERT INTO yp.contact_activity (timestamp, uid, target_uid, event, data)
        VALUES (UNIX_TIMESTAMP(), _uid, _target_uid, _event, _data);
      END IF;

    ELSEIF _event = 'task_column_change' THEN
      -- Column-watch notification: coalesce per (recipient, folder, column) while
      -- undismissed so a busy column yields ONE refreshing "activity in X" row
      -- (latest actor/timestamp/data) instead of stacking one row per change.
      SET _col_key = JSON_UNQUOTE(JSON_EXTRACT(_data, '$.column_key'));
      SET _col_nid = JSON_UNQUOTE(JSON_EXTRACT(_data, '$.nid'));

      SELECT id INTO _existing_id
        FROM yp.contact_activity
       WHERE target_uid = _target_uid
         AND event = 'task_column_change'
         AND JSON_UNQUOTE(JSON_EXTRACT(data, '$.column_key')) = _col_key
         AND IFNULL(JSON_UNQUOTE(JSON_EXTRACT(data, '$.nid')), '') = IFNULL(_col_nid, '')
         AND dismissed_at IS NULL
       ORDER BY id DESC
       LIMIT 1;

      IF _existing_id IS NOT NULL THEN
        UPDATE yp.contact_activity
           SET timestamp = UNIX_TIMESTAMP(),
               uid = _uid,
               data = _data
         WHERE id = _existing_id;
      ELSE
        INSERT INTO yp.contact_activity (timestamp, uid, target_uid, event, data)
        VALUES (UNIX_TIMESTAMP(), _uid, _target_uid, _event, _data);
      END IF;

    ELSE
      -- All other events (invite_sent, invite_accepted, invite_refused, etc.)
      -- are audit entries; allow duplicates so the history is preserved.
      INSERT INTO yp.contact_activity (timestamp, uid, target_uid, event, data)
      VALUES (UNIX_TIMESTAMP(), _uid, _target_uid, _event, _data);
    END IF;

  END IF;
END$

DELIMITER ;
