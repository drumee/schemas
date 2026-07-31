DELIMITER $




-- =========================================================
-- Verifies email of a drumate.
-- =========================================================
DROP PROCEDURE IF EXISTS `drumate_verify_email`$
CREATE PROCEDURE `drumate_verify_email`(
  IN _id          VARBINARY(16),
  IN _email_hash  VARCHAR(255),
  IN _token       VARCHAR(255)
)
BEGIN
  DECLARE _ctime INT(11);
  DECLARE _unverified_email VARCHAR(255);
  DECLARE _actual_token VARCHAR(255);

  SELECT token, ctime FROM verification WHERE drumate_id=_id ORDER BY ctime DESC LIMIT 1 INTO _actual_token, _ctime;
  SELECT unverified_email FROM drumate WHERE id=_id INTO _unverified_email;

  IF _token = _actual_token AND TRIM(IFNULL(_email_hash, '')) <>'' AND _email_hash = sha2(_unverified_email, 512) THEN
    -- `email` is a GENERATED (VIRTUAL) column -- json_value(profile,'$.email').
    -- Assigning it directly used to raise ER_WARNING_NON_DEFAULT_VALUE_FOR_
    -- GENERATED_COLUMN (1906): a warning under lenient sql_mode, an outright
    -- error under strict, and either way the row never actually committed --
    -- registration_verified stayed 0 forever, so no real signup on this stage
    -- could ever complete verification. Writing profile alone is sufficient;
    -- the generated column recomputes from it automatically.
    UPDATE drumate set profile = JSON_SET(profile, "$.email", _unverified_email),
        registration_verified=1, unverified_email = NULL WHERE id=_id;
    SELECT 1 AS updated;
  ELSE
    SELECT 0 AS updated;
  END IF;
END$
DELIMITER ;
