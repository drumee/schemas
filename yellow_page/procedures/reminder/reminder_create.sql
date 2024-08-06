DELIMITER $

DROP PROCEDURE IF EXISTS `reminder_create`$
CREATE PROCEDURE `reminder_create`(
  IN _uid VARCHAR(16),
  IN _task JSON
)
BEGIN
  DECLARE _db_name VARCHAR(116) DEFAULT NULL;
  DECLARE _id VARCHAR(16) DEFAULT NULL;
  DECLARE _st INT(11) UNSIGNED DEFAULT 0;
  SELECT UNIX_TIMESTAMP() INTO _st;
  IF _task IS NULL THEN 
    SELECT '{}' INTO _task;
  END IF;
  SELECT JSON_SET(_task, "$.ctime", _st, "$.mtime", _st) INTO _task;
  SELECT uniqueId() INTO _id;
  SELECT id FROM reminder WHERE 
    `uid`=_uid AND nid = JSON_VALUE(_task, "$.nid") AND hub_id = JSON_VALUE(_task, "$.hub_id") INTO _id;
  REPLACE INTO reminder (`id`, `uid`, `task`) VALUES (_id, _uid, _task);
  SELECT *, id reminder_id FROM reminder WHERE id=_id;
END$

DELIMITER ;

-- #####################
