DELIMITER $

-- =========================================================
-- hub_member_presence
-- One row per member of this hub with a live-socket flag and the most
-- recent activity time seen on any socket or session cookie. Grouped
-- by user so a member with several tabs appears once.
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
    GREATEST(
      IFNULL((SELECT MAX(s.mtime) FROM yp.socket s WHERE s.uid = d.id), 0),
      IFNULL((SELECT MAX(ck.mtime) FROM yp.cookie ck WHERE ck.uid = d.id), 0)
    ) AS last_seen
  FROM (SELECT DISTINCT entity_id FROM permission WHERE resource_id = '*') p
  INNER JOIN yp.drumate d ON d.id = p.entity_id
  ORDER BY `online` DESC, last_seen DESC, d.fullname;
END $

DELIMITER ;
