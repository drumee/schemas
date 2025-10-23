

DELIMITER $

DROP PROCEDURE IF EXISTS `push_mfs_events`$
CREATE PROCEDURE `push_mfs_events`(
  IN _args JSON
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _page INTEGER DEFAULT 1;

  SELECT IFNULL(JSON_VALUE(_args, "$.page"), 1) INTO _page;
  SELECT IFNULL(JSON_VALUE(_args, "$.pagelength"), 45) INTO @rows_per_page;
  CALL yp.pageToLimits(_page, _offset, _range); 

  SELECT c.*, e.db_name FROM yp.mfs_changelog c 
    LEFT JOIN push_notification p ON c.id=p.id
    INNER JOIN entity e ON c.hub_id = e.id
    WHERE p.sent IS NULL AND e.type='hub' 
    LIMIT _offset, _range;
END$
DELIMITER ;