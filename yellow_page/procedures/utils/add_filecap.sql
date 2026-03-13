DELIMITER $

DROP PROCEDURE IF EXISTS `add_filecap`$
CREATE PROCEDURE `add_filecap`(
  IN _args JSON
)
BEGIN

  INSERT IGNORE INTO filecap SELECT 
    NULL,
    IFNULL(JSON_VALUE(_args, "$.extension"), ''), 
    IFNULL(JSON_VALUE(_args, "$.category"), 'other'), 
    IFNULL(JSON_VALUE(_args, "$.mimetype"), 'application/octet-stream'), 
    IFNULL(JSON_VALUE(_args, "$.capability"), '---'), 
    IFNULL(JSON_VALUE(_args, "$.description"), 'Unknow category');
END$

DELIMITER ;