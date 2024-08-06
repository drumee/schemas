DELIMITER $
DROP PROCEDURE IF EXISTS `check_password_next`$
CREATE PROCEDURE `check_password_next`(
  IN _key VARCHAR(128),
  IN _pw VARCHAR(128)
)
BEGIN

  SELECT
    entity.id,
    entity.ident,
    db_name,
    db_host,
    fs_host,
    vhost,
    home_dir,
    type,
    status,
    email,
    firstname,
    lastname,
    area,
    mtime,
    ctime,
    fingerprint,
    fullname
  FROM entity JOIN drumate USING(id)
  WHERE fingerprint=sha2(_pw, 512) AND (ident=_key OR id=_key OR email=_key);

END$

DELIMITER $