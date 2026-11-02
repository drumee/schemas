DELIMITER $

-- =========================================================
-- drumate_presence
-- Online flag (a live socket) and last activity (newest session-cookie
-- mtime; yp.socket carries no mtime) for a JSON list of user ids — the
-- participants of a direct conversation in Chat details. Unknown ids drop.
-- =========================================================
DROP PROCEDURE IF EXISTS `drumate_presence`$
CREATE PROCEDURE `drumate_presence`(
  IN _ids JSON
)
BEGIN
  SELECT d.id, d.email, d.firstname, d.lastname, d.fullname,
    IF(EXISTS (SELECT 1 FROM socket s WHERE s.uid = d.id), 1, 0) AS `online`,
    IFNULL((SELECT MAX(ck.mtime) FROM cookie ck WHERE ck.uid = d.id), 0) AS last_seen
  FROM JSON_TABLE(_ids, '$[*]' COLUMNS (id VARCHAR(16) PATH '$')) j
  JOIN drumate d ON d.id = j.id;
END $
DELIMITER ;
