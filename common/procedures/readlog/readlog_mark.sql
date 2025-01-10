 DELIMITER $

DROP PROCEDURE IF EXISTS `readlog_mark`$
CREATE PROCEDURE `readlog_mark`(
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _hub_id INT(11),
  IN _nid INT(11)
)
BEGIN

  UPDATE readlog SET unread=0 WHERE uid=_uid AND hub_id=_hub_id AND nid=_nid;

END $

DELIMITER ;

