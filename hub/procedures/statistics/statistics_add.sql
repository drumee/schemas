DELIMITER $
DROP PROCEDURE IF EXISTS `statistics_add`$
CREATE PROCEDURE `statistics_add`(
  IN _disk_usage    INT(20)
)
BEGIN
  DECLARE _last INT(11) DEFAULT 0;
  DECLARE _page_count INT(11) DEFAULT 0;
  SELECT COUNT(serial) FROM block_history WHERE status = 'draft' OR isonline = 1 INTO _page_count;
  INSERT INTO statistics VALUES (NULL, _disk_usage, _page_count, 0, UNIX_TIMESTAMP());
  SELECT LAST_INSERT_ID() INTO _last;
  SELECT * FROM statistics WHERE sys_id = _last;
END $

DELIMITER ;