DELIMITER $
DROP PROCEDURE IF EXISTS `notification_bookmark_list`$
CREATE PROCEDURE `notification_bookmark_list`(
  IN _page INT
)
BEGIN
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _range BIGINT;
  DECLARE _offset BIGINT;

  SELECT id INTO _uid FROM yp.entity WHERE db_name = DATABASE();

  CALL yp.pageToLimits(_page, _offset, _range);

  SELECT
    id,
    uid,
    message_id,
    hub_id,
    ctime
  FROM notification_bookmark
  WHERE uid = _uid
  ORDER BY ctime DESC
  LIMIT _offset, _range;
END $
DELIMITER ;