-- =========================================================
-- entity_register
-- =========================================================

DELIMITER $


-- =========================================================
-- Delete  entity
--
-- =========================================================
DROP PROCEDURE IF EXISTS `entity_delete`$
CREATE PROCEDURE `entity_delete`(
   IN _key VARCHAR(80) CHARACTER SET ascii
)
BEGIN
  DECLARE _id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _ident VARCHAR(80) CHARACTER SET ascii;
  DECLARE _type VARCHAR(80);
  DECLARE _db VARCHAR(80);
  DECLARE _home_dir VARCHAR(512);
  DECLARE _entity_db VARCHAR(20);

  SELECT e.id, COALESCE(h.hubname, d.username), `type`, db_name, home_dir 
    FROM entity e 
      LEFT JOIN yp.hub h ON e.id=h.id 
      LEFT JOIN yp.drumate d ON e.id=d.id 
    WHERE e.id=_key OR db_name=_key INTO _id, _ident, _type, _db, _home_dir;

  DELETE FROM entity WHERE id=_id;
  DELETE FROM disk_usage WHERE hub_id=_id;
  DELETE FROM vhost WHERE id=_id;
  DELETE FROM corporate WHERE entity_id=_id;
  DELETE FROM share_box WHERE owner_id=_id;

  DELETE FROM dmz_token WHERE hub_id=_id;
  DELETE FROM privilege WHERE `uid`=_id;
  DELETE FROM map_role WHERE `uid`=_id;
  
  -- DELETE FROM map_share WHERE hub_id=_id;
  -- DELETE FROM cookie_share WHERE hub_id=_id;
  -- DELETE FROM share WHERE hub_id=_id;

  IF _type = 'drumate' THEN
    -- SELECT dmail FROM drumate WHERE id=_id INTO @dmail;
    -- DELETE FROM mailserver.users where username=_ident;
    DELETE FROM drumate WHERE id=_id;
  ELSE
    DELETE FROM hub WHERE id=_id;
  END IF;

  IF _db IS NOT NULL OR _db!="" THEN
    SET @s = CONCAT("DROP DATABASE IF EXISTS`", _db, "`");
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;

  SELECT _id id, _ident ident, _type type, _db db_name, _home_dir home_dir;
  DELETE FROM cookie WHERE uid=_id;
END$
DELIMITER ;