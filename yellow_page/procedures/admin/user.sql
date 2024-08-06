DELIMITER $

-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `user_list`$
CREATE PROCEDURE `user_list`(
  IN _sort_by VARCHAR(20),
  IN _order   VARCHAR(20),
  IN _page    TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);
  SELECT 
    e.id,
    e.ident,
    remit,
    domain,
    d.email,
    e.ctime,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.lang')), '')) AS lang,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.avatar')), 'default')) AS avatar,
    e.status,
    d.profile,
    disk_usage(e.id) AS disk_usage,
    quota,
    category,
    firstname,
    lastname,
    concat(firstname, ' ', lastname) as fullname,
    _page as page
    FROM entity e INNER JOIN (drumate d) ON e.id=d.id
      WHERE `status` IN('active', 'locked') 
      -- ORDER BY e.ctime DESC LIMIT _offset, _range;
  ORDER BY 
    CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_order) = 'asc' THEN e.ctime END ASC,
    CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_order) = 'desc' THEN e.ctime END DESC,
    CASE WHEN LCASE(_sort_by) = 'name' and LCASE(_order) = 'asc' THEN fullname END ASC,
    CASE WHEN LCASE(_sort_by) = 'name' and LCASE(_order) = 'desc' THEN fullname END DESC,
    CASE WHEN LCASE(_sort_by) = 'ident' and LCASE(_order) = 'asc' THEN e.ident END ASC,
    CASE WHEN LCASE(_sort_by) = 'ident' and LCASE(_order) = 'desc' THEN e.ident END DESC,
    CASE WHEN LCASE(_sort_by) = 'email' and LCASE(_order) = 'asc' THEN d.email END ASC,
    CASE WHEN LCASE(_sort_by) = 'email' and LCASE(_order) = 'desc' THEN d.email END DESC
  LIMIT _offset, _range;

END$


-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `user_count`$
CREATE PROCEDURE `user_count`(
)
BEGIN
  SELECT count(*) AS `count` FROM entity WHERE 
    `type`='drumate' AND `status` IN('active', 'locked');
END$

-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `user_lock`$
DROP PROCEDURE IF EXISTS `user_change_status`$
CREATE PROCEDURE `user_change_status`(
  IN _key VARCHAR(128),
  IN _status VARCHAR(16)
)
BEGIN
  UPDATE entity SET status=_status WHERE id=_key OR ident=_key;
  IF ROW_COUNT() THEN
    CALL get_user(_key);
  END IF;
END$


-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `cast_user`$
CREATE PROCEDURE `cast_user`(
  IN _admin VARCHAR(90),
  IN _user   VARCHAR(90)
)
BEGIN
  DECLARE _admin_id VARCHAR(16);
  DECLARE _user_id VARCHAR(16);
  SELECT id FROM entity e INNER JOIN drumate USING(id) WHERE id=_admin OR
    ident=_admin AND remit&2 INTO _admin_id;
  SELECT id FROM entity e INNER JOIN drumate USING(id) WHERE id=_user OR
    ident=_user INTO _user_id;
  SELECT _admin_id admin, _user_id user;
  IF _admin_id IS NULL OR _user_id IS NULL THEN 
    SELECT null id;
  ELSE 
    SELECT * FROM cookie WHERE uid=_admin_id;
    UPDATE cookie SET uid=_user_id WHERE uid=_admin_id;
  END IF;
END$

DELIMITER ;

-- #####################
