DELIMITER $

-- =========================================================
--
-- LANGUAGES
--
-- =========================================================

-- =========================================================
-- Gets list of available languages from yellow page.
-- =========================================================
DROP PROCEDURE IF EXISTS `yp_get_expired_frozen_languages`$
CREATE PROCEDURE `yp_get_expired_frozen_languages`()
BEGIN
  SELECT fl.sys_id as id, fl.hub_id, fl.dbase_name, fl.root_path, fl.job_id, fl.lang, fl.ctime,
    jc.app_key, jc.customer_key, jc.user_id
    FROM frozen_language fl INNER JOIN job_credential jc ON jc.job_id = fl.job_id
    WHERE UNIX_TIMESTAMP(TIMESTAMPADD(DAY,7, FROM_UNIXTIME(fl.ctime))) < UNIX_TIMESTAMP();
END$

-- =========================================================
-- Checks given language is available in languages from yellow page.
-- =========================================================
DROP PROCEDURE IF EXISTS `yp_check_language_available`$
CREATE PROCEDURE `yp_check_language_available`(
  IN _locale       VARCHAR(100)
)
BEGIN
  DECLARE _language_count INT(11) DEFAULT 0;
  SELECT COUNT(*) FROM language WHERE state = 'active' AND lcid = _locale INTO _language_count;
  IF _language_count > 0 THEN
    SELECT 1 AS available;
  ELSE
    SELECT 0 AS available;
  END IF;
END$

-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `language_exists`$
CREATE PROCEDURE `language_exists`(
  IN _locale       VARCHAR(100)
)
BEGIN
  SELECT COUNT(*) AS lang FROM language WHERE state = 'active' AND lcid = _locale;
END$

DELIMITER ;