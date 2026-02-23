-- Count contacts for reward hub OT6 verification.
-- Returns: contacts with status IN ('active','informed','accept') in user db.
-- Used when reward hub db connection lacks cross-db SELECT on a_*.
DELIMITER $

DROP PROCEDURE IF EXISTS `count_user_contacts`$
CREATE PROCEDURE `count_user_contacts`(
  IN _uid VARCHAR(16)
)
BEGIN
  DECLARE _user_db VARCHAR(64);
  DECLARE _cnt INT UNSIGNED DEFAULT 0;

  SELECT db_name INTO _user_db FROM entity WHERE id = _uid LIMIT 1;
  IF _user_db IS NOT NULL AND CHAR_LENGTH(TRIM(COALESCE(_user_db, ''))) > 0 THEN
    SET @sql = CONCAT(
      'SELECT COUNT(*) INTO @contact_cnt FROM `', _user_db, '`.contact ',
      'WHERE status IN (', QUOTE('active'), ', ', QUOTE('informed'), ', ', QUOTE('accept'), ')'
    );
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    SET _cnt = IFNULL(@contact_cnt, 0);
  END IF;

  SELECT _cnt AS cnt;
END$

DELIMITER ;
