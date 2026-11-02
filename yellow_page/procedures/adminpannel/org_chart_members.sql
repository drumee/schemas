DELIMITER $

-- =========================================================
-- org_chart_members
-- =========================================================
-- The people of the Org Structure chart: active members of the organisation's
-- domain (yp.privilege), named from yp.drumate. Workspace collaborators from
-- other domains have no privilege row here and are deliberately absent.
-- Capped at 501 rows: admin.org_chart charts 500 and uses the 501st only to
-- say the list was truncated. Ordered so the cut is stable across loads.
DROP PROCEDURE IF EXISTS `org_chart_members`$
CREATE PROCEDURE `org_chart_members`(
  IN _domain_id INT
)
BEGIN
  SELECT
    d.id        AS uid,
    d.firstname,
    d.lastname,
    d.fullname,
    d.email,
    p.privilege
  FROM privilege p
  INNER JOIN drumate d ON d.id = p.uid
  INNER JOIN entity e  ON e.id = p.uid
  WHERE p.domain_id = _domain_id
    AND e.status = 'active'
  ORDER BY d.lastname, d.firstname, d.id
  LIMIT 501;
END$

DELIMITER ;
