DELIMITER $

DROP PROCEDURE IF EXISTS `get_user_in_domain`$
CREATE PROCEDURE `get_user_in_domain`(
  IN _key VARCHAR(512),
  IN _domain_name VARCHAR(1000)
)
BEGIN
  DECLARE _id VARCHAR(16);
  DECLARE _sb_id VARCHAR(16);
  DECLARE _sb_db VARCHAR(50);
  DECLARE _sb_root VARCHAR(16);
  DECLARE _avatar VARCHAR(16);
  DECLARE _disk_usage float(16);
  DECLARE _exists BOOLEAN DEFAULT 1;

  SELECT e.id FROM entity e INNER JOIN(drumate d, domain m) ON e.id=d.id AND e.dom_id = m.id
    WHERE (d.username=_key AND (m.name = _domain_name OR m.id = _domain_name)) OR
    e.id=_key OR d.email=_key INTO _id;
  SELECT s.id, e.db_name, root_id FROM share_box s INNER JOIN yp.entity e USING(id)
  WHERE area = 'restricted' AND owner_id=_id INTO _sb_id, _sb_db, _sb_root;
  
  SELECT sum(e.space) FROM hub h LEFT JOIN entity e USING(id) 
    WHERE e.id=_id or h.owner_id = _id INTO _disk_usage;
  
  IF _id IS NULL OR _id = '' OR _key = '' THEN
    SELECT yp.nobody_id() INTO _id;
    SELECT 0 INTO _exists;
  END IF;
  -- SELECT photo FROM `profile` WHERE drumate_id=_id and area='public' INTO _avatar;
  SELECT
    ee.id,
    ee.id as hub_id,
    dr.username AS ident,
    dr.username AS username,
    _sb_id AS sb_id,
    _sb_db AS sb_db,
    _sb_root AS sb_root,
    db_name,
    home_dir,
    pr.privilege AS remit,
    mtime,
    ctime,
    dd.name AS domain,
    lang,
    avatar,
    status,
    profile,
    settings,
    disk_usage(ee.id) AS disk_usage,
    quota,
    firstname,
    lastname,
    fullname,
    _exists AS `exists`
    FROM entity ee INNER JOIN (drumate dr, domain dd, privilege pr) 
    ON ee.id=dr.id AND dd.id=ee.dom_id AND dr.id=pr.uid WHERE ee.id=_id
    GROUP BY(ee.id);
END$
DELIMITER ;