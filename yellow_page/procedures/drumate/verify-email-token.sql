DELIMITER $

-- =========================================================
-- drumate_verify_email_token
-- Verifies a signup email using only the token from the
-- verification link. On success promotes unverified_email to
-- the live email and flips registration_verified. 24h expiry.
-- =========================================================
DROP PROCEDURE IF EXISTS `drumate_verify_email_token`$
CREATE PROCEDURE `drumate_verify_email_token`(
  IN _token VARCHAR(255)
)
BEGIN
  DECLARE _id    VARBINARY(16) DEFAULT NULL;
  DECLARE _ctime INT(11) DEFAULT 0;

  SELECT drumate_id, ctime INTO _id, _ctime
    FROM verification WHERE token = _token LIMIT 1;

  IF _id IS NOT NULL AND (UNIX_TIMESTAMP() - _ctime) <= 86400 THEN
    UPDATE drumate
      SET profile = JSON_SET(profile, "$.email", IFNULL(unverified_email, JSON_VALUE(profile, "$.email"))),
          registration_verified = 1,
          unverified_email = NULL
      WHERE id = _id;
    DELETE FROM verification WHERE drumate_id = _id;
    SELECT 1 AS verified;
  ELSE
    SELECT 0 AS verified;
  END IF;
END $

DELIMITER ;
