DELIMITER $

-- =========================================================
-- admin_access_request_dismiss
-- Mark pending request(s) dismissed. Empty _requester_uid
-- dismisses every pending row for the domain.
-- =========================================================
DROP PROCEDURE IF EXISTS `admin_access_request_dismiss`$
CREATE PROCEDURE `admin_access_request_dismiss`(
  IN _domain_id INT,
  IN _dismisser_uid VARCHAR(16),
  IN _requester_uid VARCHAR(16)
)
BEGIN
  UPDATE admin_access_request
  SET
    status = 'dismissed',
    dismissed_by = _dismisser_uid,
    dismissed_at = UNIX_TIMESTAMP(),
    mtime = UNIX_TIMESTAMP()
  WHERE domain_id = _domain_id
    AND status = 'pending'
    AND (
      IFNULL(_requester_uid, '') = ''
      OR requester_uid = _requester_uid
    );

  SELECT ROW_COUNT() AS dismissed;
END $

DELIMITER ;
