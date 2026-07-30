DELIMITER $

-- =========================================================
-- admin_access_request_create
-- Idempotent upsert of a pending Admin Console access request
-- for (_domain_id, _requester_uid). Re-request refreshes mtime.
-- =========================================================
DROP PROCEDURE IF EXISTS `admin_access_request_create`$
CREATE PROCEDURE `admin_access_request_create`(
  IN _domain_id INT,
  IN _requester_uid VARCHAR(16)
)
BEGIN
  DECLARE _existing_id VARCHAR(16) CHARACTER SET ascii DEFAULT NULL;
  DECLARE _new_id VARCHAR(16) CHARACTER SET ascii;

  SELECT id INTO _existing_id
  FROM admin_access_request
  WHERE domain_id = _domain_id
    AND requester_uid = _requester_uid
    AND status = 'pending'
  LIMIT 1;

  IF _existing_id IS NOT NULL THEN
    UPDATE admin_access_request
    SET mtime = UNIX_TIMESTAMP()
    WHERE id = _existing_id;

    SELECT id, domain_id, requester_uid, status, ctime, mtime
    FROM admin_access_request
    WHERE id = _existing_id;
  ELSE
    SELECT yp.uniqueId() INTO _new_id;

    INSERT INTO admin_access_request
      (id, domain_id, requester_uid, status, ctime, mtime)
    VALUES
      (_new_id, _domain_id, _requester_uid, 'pending', UNIX_TIMESTAMP(), UNIX_TIMESTAMP());

    SELECT id, domain_id, requester_uid, status, ctime, mtime
    FROM admin_access_request
    WHERE id = _new_id;
  END IF;
END $

DELIMITER ;
