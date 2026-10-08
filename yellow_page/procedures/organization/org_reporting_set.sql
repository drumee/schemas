DELIMITER $

-- =========================================================
-- org_reporting_set
-- =========================================================
-- Set who a person reports to; NULL or '' clears it (they report to the
-- owner again). Cycles are refused by the service, which has the whole tree.
DROP PROCEDURE IF EXISTS `org_reporting_set`$
CREATE PROCEDURE `org_reporting_set`(
  IN _domain_id INT UNSIGNED, IN _uid VARCHAR(16), IN _manager VARCHAR(16)
)
BEGIN
  IF IFNULL(_manager, '') = '' THEN
    DELETE FROM org_reporting WHERE domain_id = _domain_id AND uid = _uid;
  ELSE
    INSERT INTO org_reporting (domain_id, uid, manager_uid, mtime)
      VALUES (_domain_id, _uid, _manager, UNIX_TIMESTAMP())
      ON DUPLICATE KEY UPDATE manager_uid = VALUES(manager_uid), mtime = VALUES(mtime);
  END IF;
  SELECT _uid AS uid, NULLIF(_manager, '') AS manager_uid;
END$

DELIMITER ;
