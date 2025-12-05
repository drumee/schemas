-- File: schemas/yellow_page/procedures/contact/contact_log_activity.sql
-- Purpose: Log contact activity events to yp.contact_activity table

DELIMITER $

DROP PROCEDURE IF EXISTS `contact_log_activity`$

CREATE PROCEDURE `contact_log_activity`(
  IN _uid VARCHAR(16),           -- User who triggered the action
  IN _target_uid VARCHAR(16),    -- User who receives the action
  IN _event VARCHAR(100),        -- Event type: invite_sent, invite_received, invite_accepted, invite_refused
  IN _data JSON
)
BEGIN
  -- Only log if both users exist (skip email-only invites)
  IF _uid IS NOT NULL AND _uid != '' AND _target_uid IS NOT NULL AND _target_uid != '' THEN
    INSERT INTO yp.contact_activity (
      timestamp,
      uid,
      target_uid,
      event,
      data
    ) VALUES (
      UNIX_TIMESTAMP(),
      _uid,
      _target_uid,
      _event,
      _data
    );
  END IF;
END$

DELIMITER ;