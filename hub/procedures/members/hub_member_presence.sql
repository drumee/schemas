DELIMITER $

-- =========================================================
-- hub_member_presence
-- One row per member of this hub with a live-socket flag and the most
-- recent session-cookie activity time (yp.socket carries no mtime, and
-- a socket row only exists while the member is online anyway). One row
-- per user however many tabs or sessions they hold.
-- =========================================================
DROP PROCEDURE IF EXISTS `hub_member_presence`$
CREATE PROCEDURE `hub_member_presence`()
BEGIN
  SELECT
    d.id,
    d.email,
    d.firstname,
    d.lastname,
    d.fullname,
    IF(EXISTS (SELECT 1 FROM yp.socket s WHERE s.uid = d.id), 1, 0) AS `online`,
    IFNULL((SELECT MAX(ck.mtime) FROM yp.cookie ck WHERE ck.uid = d.id), 0) AS last_seen
  FROM (SELECT DISTINCT entity_id FROM permission WHERE resource_id = '*') p
  INNER JOIN yp.drumate d ON d.id = p.entity_id
  ORDER BY `online` DESC, last_seen DESC, d.fullname;
END $

DELIMITER ;
