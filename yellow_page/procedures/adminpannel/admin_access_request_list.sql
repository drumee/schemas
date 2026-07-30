DELIMITER $

-- =========================================================
-- admin_access_request_list
-- Pending Admin Console access requests for a domain, with
-- requester display fields from drumate.
-- =========================================================
DROP PROCEDURE IF EXISTS `admin_access_request_list`$
CREATE PROCEDURE `admin_access_request_list`(
  IN _domain_id INT
)
BEGIN
  SELECT
    r.id,
    r.domain_id,
    r.requester_uid AS uid,
    COALESCE(NULLIF(d.fullname, ''), NULLIF(d.email, ''), r.requester_uid) AS name,
    COALESCE(d.email, '') AS email,
    r.status,
    r.ctime,
    r.mtime
  FROM admin_access_request r
  LEFT JOIN drumate d ON d.id = r.requester_uid
  WHERE r.domain_id = _domain_id
    AND r.status = 'pending'
  ORDER BY r.ctime DESC;
END $

DELIMITER ;
