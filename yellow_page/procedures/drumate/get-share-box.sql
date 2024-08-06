DELIMITER $


-- =========================================================
-- Checks whether drumate with given id/email exist or not.
-- =========================================================
DROP PROCEDURE IF EXISTS `drumate_get_share_box`$
CREATE PROCEDURE `drumate_get_share_box`(
  IN _id          VARCHAR(500)
)
BEGIN
  DECLARE _db_name VARCHAR(30);
  DECLARE _inbound_id VARCHAR(16);
  DECLARE _outbound_id VARCHAR(16);
  DECLARE _dp TINYINT(4);
  DECLARE _drumate_id VARCHAR(16);
  DECLARE _drumate_db VARCHAR(160);
  DECLARE _sb_id VARCHAR(16);

  SELECT e.id, JSON_VALUE(`settings`, "$.default_privilege"), db_name
    FROM yp.hub h INNER JOIN yp.entity e USING(id) 
    WHERE area = 'restricted' and owner_id=_id INTO _sb_id, _dp, _db_name;

  SET @outbound = NULL;
  SET @inbound = NULL;
  IF _db_name IS NOT NULL THEN 
    SET @s = CONCAT("SELECT `", _db_name, 
      "`.node_id_from_path('/__Outbound__') INTO @outbound");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    SET @s = CONCAT("SELECT `", _db_name, 
      "`.node_id_from_path('/__Inbound__') INTO @inbound");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    SELECT 
      e.id as hub_id,
      hubname AS ident,
      hubname,
      space,
      ctime,
      icon,
      home_id AS root_id,
      home_id,
      vhost(_sb_id) AS vhost,
      _dp as default_privilege,
      @outbound as outbound,
      @inbound as inbound
    FROM entity e
    LEFT JOIN hub h ON e.id = h.id WHERE h.id = _sb_id;
  END IF;
END$

DELIMITER ;
