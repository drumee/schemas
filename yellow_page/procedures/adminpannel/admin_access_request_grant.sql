DELIMITER $

-- =========================================================
-- admin_access_request_grant
-- Mark the pending request for one requester as granted
-- after the owner/admin has elevated their org privilege.
-- =========================================================
DROP PROCEDURE IF EXISTS `admin_access_request_grant`$
CREATE PROCEDURE `admin_access_request_grant`(
  IN _domain_id INT,
  IN _granter_uid VARCHAR(16),
  IN _requester_uid VARCHAR(16)
)
BEGIN
  UPDATE admin_access_request
  SET
    status = 'granted',
    granted_by = _granter_uid,
    granted_at = UNIX_TIMESTAMP(),
    mtime = UNIX_TIMESTAMP()
  WHERE domain_id = _domain_id
    AND requester_uid = _requester_uid
    AND status = 'pending';

  SELECT ROW_COUNT() AS granted;
END $

DELIMITER ;
