DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_get_autorized_node`$
CREATE PROCEDURE `mfs_get_autorized_node`(
  IN _sessionKey VARCHAR(64) CHARACTER SET ascii
)
BEGIN
  DECLARE _db_name VARCHAR(264) CHARACTER SET ascii;
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _nid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _expiry INT UNSIGNED;

  SELECT expiry, nid, uid, db_name 
    FROM mfs_authorized_node n INNER JOIN entity e ON e.id=n.hub_id 
    WHERE sessionKey=_sessionKey INTO _expiry, _nid, _uid, _db_name;
  IF _db_name IS NOT NULL AND (_expiry=0 OR UNIX_TIMESTAMP()<_expiry) THEN 
    SET @s = CONCAT("CALL ", _db_name, ".mfs_access_node(?, ?)");
    PREPARE stmt FROM @s;
    EXECUTE stmt USING _uid, _nid;
    DEALLOCATE PREPARE stmt;
    SELECT _uid uid, _db_name db_name;
  END IF;
END$

DELIMITER ;