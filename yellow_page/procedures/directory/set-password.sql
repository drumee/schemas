DELIMITER $

-- =========================================================
-- Change drumate password
-- Admin API
-- =========================================================
DROP PROCEDURE IF EXISTS `set_password`$
CREATE PROCEDURE `set_password`(
  IN _uid VARCHAR(160),
  IN _pw VARCHAR(128)
)
BEGIN
  DECLARE _id VARCHAR(40);
  SELECT id FROM drumate WHERE id=_uid or email=_uid INTO _id;
  UPDATE drumate SET fingerprint=sha2(_pw, 512) WHERE id=_id;
  SELECT 
    e.id,
    link AS domain,
    o.domain_id,
    username,
    username as ident,
    db_name,
    db_host,
    fs_host,
    vhost,
    home_dir,
    type,
    status,
    email,
    JSON_VALUE(profile, "$.mobile")  mobile,
    JSON_VALUE(profile, "$.areacode")  areacode,
    firstname as nickname,
    lastname,
    area,
    mtime,
    ctime,
    fingerprint,
    otp
  FROM entity e 
    INNER JOIN drumate d on e.id=d.id 
    INNER JOIN organisation o ON o.domain_id=e.dom_id
  WHERE d.id=_uid;
END$
