DELIMITER $

-- =========================================================
-- admin_access_request_get
-- The caller's own pending Admin Console access request for
-- a domain (if any). Used by the member upsell overlay so a
-- reload still shows "Request sent" instead of the Ask link.
-- =========================================================
DROP PROCEDURE IF EXISTS `admin_access_request_get`$
CREATE PROCEDURE `admin_access_request_get`(
  IN _domain_id INT,
  IN _requester_uid VARCHAR(16)
)
BEGIN
  SELECT
    r.id,
    r.domain_id,
    r.requester_uid AS uid,
    r.status,
    r.ctime,
    r.mtime
  FROM admin_access_request r
  WHERE r.domain_id = _domain_id
    AND r.requester_uid = _requester_uid
    AND r.status = 'pending'
  LIMIT 1;
END $

DELIMITER ;
