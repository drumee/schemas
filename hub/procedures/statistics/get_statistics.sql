DELIMITER $
DROP PROCEDURE IF EXISTS `get_statistics`$
CREATE PROCEDURE `get_statistics`()
BEGIN
  SELECT sys_id AS ID,
  disk_usage,
  page_count,
  visit_count
  FROM statistics ORDER BY sys_id DESC LIMIT 1;
END $



DELIMITER ;