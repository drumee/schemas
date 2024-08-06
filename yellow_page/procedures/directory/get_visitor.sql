-- =========================================================
-- get_visitor
-- =========================================================
DELIMITER $

DROP PROCEDURE IF EXISTS `get_visitor`$
CREATE PROCEDURE `get_visitor`(
  IN _key VARCHAR(512)
)
BEGIN
  DECLARE _uid VARCHAR(16);
  DECLARE _sb_id VARCHAR(16);
  DECLARE _sb_db VARCHAR(50);
  DECLARE _sb_root VARCHAR(16);
  DECLARE _avatar VARCHAR(16);
  DECLARE _disk_usage float(16);
  DECLARE _logged_in BOOLEAN DEFAULT 1;

  SELECT e.id FROM entity e LEFT JOIN(drumate u) USING(id) WHERE 
    e.id=_key OR u.email=_key INTO _uid;

  SELECT e.id, db_name, home_id
    FROM yp.hub h INNER JOIN yp.entity e USING(id) 
    WHERE area = 'restricted' and owner_id=_uid INTO _sb_id, _sb_db, _sb_root;
  
  SELECT sum(e.space) FROM hub h LEFT JOIN entity e USING(id) 
    WHERE e.id=_uid or h.owner_id = _uid INTO _disk_usage;
  
  IF _uid IS NULL OR _uid IN('', '*') OR _key IN('', '*')THEN
    SET _uid = 'ffffffffffffffff';
    SET _logged_in=0;
  END IF;
  -- SELECT photo FROM `profile` WHERE drumate_id=_id and area='public' INTO _avatar;
  SELECT
    e.id,
    e.id as oid,
    e.id as hub_id,
    u.username AS ident,
    u.username,
    _sb_id AS sb_id,
    _sb_db AS sb_db,
    _sb_root AS sb_root,
    db_name,
    _logged_in AS logged_in,
    home_dir,
    remit,
    mtime,
    ctime,
    domain,
    lang,
    avatar,
    status,
    profile,
    settings,
    disk_usage(e.id) AS disk_usage,
    quota,
    fullname
    FROM entity e 
      INNER JOIN drumate u ON u.id=e.id
      INNER JOIN privilege p ON p.uid=e.id
      INNER JOIN domain d ON d.id=e.dom_id
    WHERE e.id=_uid GROUP BY (e.id);
END$

DELIMITER ;