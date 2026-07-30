DELIMITER $

DROP PROCEDURE IF EXISTS `meeting_schedule_upsert`$
CREATE PROCEDURE `meeting_schedule_upsert`(
  IN _hub_id VARCHAR(16),
  IN _nid VARCHAR(16),
  IN _stime INT(11) UNSIGNED,
  IN _etime INT(11) UNSIGNED,
  IN _created_by VARCHAR(16),
  IN _title VARCHAR(255),
  IN _message TEXT,
  IN _attendees JSON,
  IN _recur JSON
)
BEGIN
  DECLARE _id VARCHAR(16) DEFAULT NULL;
  DECLARE _old_stime INT(11) UNSIGNED DEFAULT NULL;
  DECLARE _st INT(11) UNSIGNED DEFAULT UNIX_TIMESTAMP();
  IF _attendees IS NULL THEN SELECT JSON_ARRAY() INTO _attendees; END IF;
  SELECT id, stime FROM meeting_schedule
    WHERE hub_id=_hub_id AND nid=_nid INTO _id, _old_stime;
  IF _id IS NULL THEN
    SELECT uniqueId() INTO _id;
    INSERT INTO meeting_schedule
      (`id`,`hub_id`,`nid`,`stime`,`etime`,`created_by`,`title`,`message`,`attendees`,`recur`,`fired`,`ctime`,`mtime`)
      VALUES
      (_id,_hub_id,_nid,_stime,_etime,_created_by,_title,_message,_attendees,_recur,0,_st,_st);
  ELSE
    -- A moved start time re-arms both reminders (flags back to 0); an edit that
    -- leaves stime alone keeps the existing state so we don't double-fire.
    UPDATE meeting_schedule SET
      `stime`=_stime, `etime`=_etime, `created_by`=_created_by, `title`=_title, `message`=_message,
      `attendees`=_attendees, `recur`=_recur, `mtime`=_st,
      `fired`=IF(_stime <> _old_stime, 0, `fired`),
      `early_fired`=IF(_stime <> _old_stime, 0, `early_fired`)
      WHERE id=_id;
  END IF;
  SELECT * FROM meeting_schedule WHERE id=_id;
END$

DELIMITER ;

-- #####################
