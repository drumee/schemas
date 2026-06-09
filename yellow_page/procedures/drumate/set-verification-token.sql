DELIMITER $

-- =========================================================
-- drumate_set_verification_token
-- Mints a fresh email-verification token for a drumate and
-- stages the address in unverified_email. Returns the token
-- (used as the ?token= secret in the verify link).
-- Replaces any existing token for the drumate (one active
-- verification token per user at a time).
-- =========================================================
DROP PROCEDURE IF EXISTS `drumate_set_verification_token`$
CREATE PROCEDURE `drumate_set_verification_token`(
  IN _id    VARBINARY(16),
  IN _email VARCHAR(255)
)
BEGIN
  DECLARE _token VARCHAR(255);

  SELECT sha2(uuid(), 224) INTO _token;

  DELETE FROM verification WHERE drumate_id = _id;
  INSERT INTO verification (drumate_id, token, ctime)
    VALUES (_id, _token, UNIX_TIMESTAMP());

  UPDATE drumate SET unverified_email = _email WHERE id = _id;

  SELECT _token AS token;
END $

DELIMITER ;
