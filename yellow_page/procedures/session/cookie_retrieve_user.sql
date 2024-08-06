DELIMITER $

DROP PROCEDURE IF EXISTS `cookie_retrieve_user`$
CREATE PROCEDURE `cookie_retrieve_user`(
  IN _key VARCHAR(512) CHARACTER SET ascii
)
BEGIN
  DECLARE _id VARCHAR(16);
  DECLARE _sb_id VARCHAR(16);
  DECLARE _sb_db VARCHAR(50);
  DECLARE _sb_root VARCHAR(16);
  DECLARE _avatar VARCHAR(16);
  DECLARE _disk_usage float(16);

  DECLARE _uid VARCHAR(16) CHARACTER SET ascii;
  SELECT `uid` FROM cookie WHERE id=_key LIMIT 1 INTO _uid;
  CALL get_user(_uid);
  
  -- SELECT e.id FROM entity e LEFT JOIN(drumate u) USING(id) WHERE e.id=_uid INTO _id;
  
  -- SELECT sum(e.space) FROM hub h LEFT JOIN entity e USING(id) 
  --   WHERE e.id=_id or h.owner_id = _id INTO _disk_usage;
  
  -- SELECT
  --   e.id,
  --   e.id as hub_id,
  --   u.username AS ident,
  --   db_name,
  --   domain_name(db_name) AS domain,
  --   domain_id(db_name) AS domain_id,
  --   home_dir,
  --   remit,
  --   mtime,
  --   ctime,
  --   d.name AS `domain`,
  --   lang,
  --   avatar,
  --   status,
  --   profile,
  --   settings,
  --   disk_usage(e.id) AS disk_usage,
  --   quota,
  --   fullname
  --   FROM entity e INNER JOIN (drumate u, privilege p, domain d)
  --     ON e.id=u.id AND p.uid=u.id AND d.id=p.domain_id  WHERE u.id=_id;
END$


DELIMITER ;