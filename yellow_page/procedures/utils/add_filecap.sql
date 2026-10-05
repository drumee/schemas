DELIMITER $

DROP PROCEDURE IF EXISTS `add_filecap`$
CREATE PROCEDURE `add_filecap`(
  IN _args JSON
)
BEGIN
  DECLARE _extension VARCHAR(1024);
  SELECT IFNULL(JSON_VALUE(_args, "$.extension"), '') INTO _extension;

  -- The extension is used to build file paths on disk: record only a plain
  -- one (letters/digits joined by single . - _, at most 16 characters), the
  -- same rule as server-team service/lib/file-extension.js.
  IF _extension = '' OR (CHAR_LENGTH(_extension) <= 16 AND
    _extension REGEXP '^[a-zA-Z0-9]+([._-][a-zA-Z0-9]+)*$') THEN
    INSERT IGNORE INTO filecap SELECT 
      NULL,
      _extension, 
      IFNULL(JSON_VALUE(_args, "$.category"), 'other'), 
      IFNULL(JSON_VALUE(_args, "$.mimetype"), 'application/octet-stream'), 
      IFNULL(JSON_VALUE(_args, "$.capability"), '---'), 
      IFNULL(JSON_VALUE(_args, "$.description"), 'Unknow category');
  END IF;
END$

DELIMITER ;