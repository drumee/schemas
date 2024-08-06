DELIMITER $

-- =========================================================
--
-- VALIDATION_CODE
--
-- =========================================================

-- =========================================================
-- Adds validation codes for different actions.
-- =========================================================
DROP PROCEDURE IF EXISTS `yp_add_validation_code`$
CREATE PROCEDURE `yp_add_validation_code`(
  IN _id            VARCHAR(16),
  IN _action        VARCHAR(100),
  IN _expiry_time   INT(11) UNSIGNED
)
BEGIN
  DECLARE duplicate_key CONDITION FOR 1062;
  DECLARE _ts INT(11) DEFAULT 0;
  DECLARE _last INT(11) DEFAULT 0;
  DECLARE _code VARCHAR(255);
  DECLARE EXIT HANDLER FOR duplicate_key
  BEGIN
    SELECT sys_id FROM validation_code WHERE id = _id AND `action` = _action INTO _last;
    UPDATE validation_code SET code = _code, expiry_time = IF(IFNULL(_expiry_time, 0) = 0, 0,
      UNIX_TIMESTAMP(TIMESTAMPADD(MINUTE,_expiry_time, FROM_UNIXTIME(_ts)))), ctime = _ts
      WHERE sys_id = _last;
    SELECT * FROM validation_code WHERE sys_id = _last;
  END;
  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT IF (_action= 'forgot_password',sha2(uuid(),224), FLOOR(100000 + (RAND() * 899999))) INTO _code;
  INSERT INTO validation_code VALUES (NULL, _id, _action, _code, IF(IFNULL(_expiry_time, 0) = 0, 0,
    UNIX_TIMESTAMP(TIMESTAMPADD(MINUTE,_expiry_time, FROM_UNIXTIME(_ts)))), _ts);
  SELECT LAST_INSERT_ID() INTO _last;
  SELECT * FROM validation_code WHERE sys_id = _last;
END$

-- =========================================================
-- Checks verification code validity.
-- =========================================================
DROP PROCEDURE IF EXISTS `yp_check_code_validity`$
CREATE PROCEDURE `yp_check_code_validity`(
  IN _id            VARCHAR(16),
  IN _action        VARCHAR(100),
  IN _code          VARCHAR(255)
)
BEGIN
   SELECT EXISTS (SELECT id FROM validation_code WHERE id = _id AND
    action = _action AND code = _code  AND  expiry_time>=UNIX_TIMESTAMP() ) AS valid;
END$

-- =========================================================
-- Deletes all expired validation code.
-- =========================================================
DROP PROCEDURE IF EXISTS `yp_delete_expired_validation_code`$
CREATE PROCEDURE `yp_delete_expired_validation_code`()
BEGIN
  DELETE FROM validation_code WHERE (expiry_time <> 0 AND expiry_time < UNIX_TIMESTAMP());
END$


-- =========================================================
-- Deletes completed validation code.
-- =========================================================
DROP PROCEDURE IF EXISTS `yp_delete_completed_validation_code`$
CREATE PROCEDURE `yp_delete_completed_validation_code`(
  IN _id            VARCHAR(16),
  IN _action        VARCHAR(100),
  IN _code          VARCHAR(255)
)
BEGIN
  DELETE FROM validation_code WHERE id = _id AND  action = _action AND code = _code ;
END$



DELIMITER ;