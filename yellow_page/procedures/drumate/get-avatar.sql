DELIMITER $



-- =========================================================
-- drumate_get_avatar
-- =========================================================
DROP PROCEDURE IF EXISTS `drumate_get_avatar`$
CREATE PROCEDURE `drumate_get_avatar`(
  IN _key VARCHAR(1024)
)
BEGIN
  DECLARE _id VARCHAR(16);
  DECLARE _resource_id VARCHAR(16);
  DECLARE _db_name VARCHAR(40);

  SET @nobody = 'ffffffffffffffff';
  SELECT id FROM drumate WHERE id=_key INTO _id;
  IF _id IS NULL OR _id = '' THEN
    SET _id = @nobody;
  END IF;

  SELECT db_name FROM entity WHERE id = _id INTO _db_name;
  SELECT TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.avatar')), 'default'))
    FROM drumate WHERE id=_id INTO _resource_id;

  SET @perm = 0;
  SET @s = CONCAT("SELECT " ,_db_name,".user_permission(?, ?) INTO @perm");
  PREPARE stmt FROM @s;
  EXECUTE stmt USING @nobody, _resource_id;
  DEALLOCATE PREPARE stmt;   

  SELECT
    entity.id,
    entity.vhost,
    entity.id as oid,
    entity.db_name,
    drumate.username,
    drumate.username AS ident,
    @perm AS permission,
    _resource_id as avatar,
    ctime,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.lang')), '')) AS lang,
    IFNULL(_resource_id, 'default') AS avatar,
    status,
    CONCAT(firstname, ' ', lastname) as fullname,
    if((UNIX_TIMESTAMP() - connexion_time)<120, 'on', 'off') as online
    FROM entity INNER JOIN (drumate) USING(id) WHERE id=_id;
END$

DELIMITER ;
