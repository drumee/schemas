DROP PROCEDURE IF EXISTS `share_track_add`;
DELIMITER $$
CREATE PROCEDURE `share_track_add`(
  IN _event    VARCHAR(64),
  IN _actor_id VARCHAR(16) CHARACTER SET ascii,
  IN _nid      VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  DECLARE _inserted INT DEFAULT 0;
  DECLARE _row_id   INT DEFAULT 0;

  INSERT IGNORE INTO `share_track` (`event`, `actor_id`, `nid`, `ctime`)
  VALUES (_event, _actor_id, _nid, UNIX_TIMESTAMP());

  SET _inserted = ROW_COUNT();
  SET _row_id   = IF(_inserted > 0, LAST_INSERT_ID(), 0);

  IF _row_id > 0 THEN
    SELECT
      _inserted AS inserted,
      st.sys_id,
      st.event,
      st.actor_id,
      st.nid,
      st.ctime,
      COALESCE(d.firstname, du.name, 'Guest') AS firstname,
      COALESCE(d.lastname,  '') AS lastname
    FROM  `share_track` st
    LEFT  JOIN yp.drumate  d  ON st.actor_id = d.id
    LEFT  JOIN yp.dmz_user du ON st.actor_id = du.id
    WHERE st.sys_id = _row_id;
  ELSE
    SELECT
      0 AS inserted,
      st.sys_id,
      st.event,
      st.actor_id,
      st.nid,
      st.ctime,
      COALESCE(d.firstname, du.name, 'Guest') AS firstname,
      COALESCE(d.lastname,  '') AS lastname
    FROM  `share_track` st
    LEFT  JOIN yp.drumate  d  ON st.actor_id = d.id
    LEFT  JOIN yp.dmz_user du ON st.actor_id = du.id
    WHERE st.actor_id <=> _actor_id
      AND st.event    = _event
    LIMIT 1;
  END IF;
END$$
DELIMITER ;