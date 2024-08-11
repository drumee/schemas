DELIMITER $


-- =========================================================
-- select common hubs for two drumates
--
-- =========================================================

DROP PROCEDURE IF EXISTS `common_hubs`$
CREATE PROCEDURE `common_hubs`(
   IN _usr1 VARBINARY(80),
   IN _usr2 VARBINARY(80)
)
BEGIN
  DECLARE _db1 varchar(255);
  DECLARE _db2 varchar(255);
  DECLARE _ident VARBINARY(80);

  SELECT db_name from yp.entity where ident=_usr1 OR id=_usr1 INTO _db1;
  SELECT db_name from yp.entity where ident=_usr2 OR id=_usr2 INTO _db2;

  SET @s1 = CONCAT("SELECT entity.id, area from entity inner join (`", _db1, "`.sites, `", _db2, "`.sites) on (`", _db1, "`.sites.id=`", _db2, "`.sites.id and entity.id=`", _db2, "`.sites.id)");

  PREPARE stmt1 FROM @s1;
  EXECUTE stmt1;
  DEALLOCATE PREPARE stmt1;

  SELECT @s1;

END$


-- =========================================================
-- select the drumate profile photo for visitor based on vhost
--
-- =========================================================

DROP PROCEDURE IF EXISTS `get_profile_photo`$
CREATE PROCEDURE `get_profile_photo`(
   IN _uid VARBINARY(16),
   IN _vhost varchar(255)
)
BEGIN
  DECLARE _area varchar(30);
  DECLARE _res VARBINARY(16);

  SELECT area FROM `alias` INNER JOIN entity USING(id) WHERE `alias`.vhost=_vhost INTO _area;

  SELECT photo FROM profile WHERE id=CONCAT(_uid, "@", _area);

END$

DELIMITER ;

-- #####################
