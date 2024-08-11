DELIMITER $


-- =======================================================================
-- db/schemas/costums/0_8544d9708544d971-support/support.sql
-- =======================================================================
DROP PROCEDURE IF EXISTS `support_bug_report`$
CREATE PROCEDURE `support_bug_report`(
  IN _user_id varchar(16),
  IN _feature varchar(60),
  IN _description mediumtext,
  IN _context mediumtext,
  IN _location mediumtext,
  IN _navigator mediumtext,
  IN _browser mediumtext,
  IN _frequency varchar(60),
  IN _category varchar(60)
)
BEGIN
  DECLARE _ts INT(20);
  DECLARE _count INTEGER;
  IF JSON_VALID(_context) THEN 
    -- SELECT UNIX_TIMESTAMP() INTO _ts;
    SELECT JSON_UNQUOTE(JSON_EXTRACT(_context, "$.timestamp"))/1000 INTO @ts;
  ELSE
    SELECT UNIX_TIMESTAMP() INTO _ts;
  END IF;

  INSERT INTO bug_report VALUES(
    null, 
    _user_id,
    0, 
    _feature,
    _description,
    _context,
    _location,
    _navigator,
    _browser,
    _frequency,
    _category,
    UNIX_TIMESTAMP(),
    @ts
  );
END$

DELIMITER ;
