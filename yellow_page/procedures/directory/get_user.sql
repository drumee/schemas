DELIMITER $


DROP PROCEDURE IF EXISTS `get_user`$
CREATE PROCEDURE `get_user`(
  IN _key VARCHAR(512) CHARACTER SET ascii
)
BEGIN
  DECLARE _id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _avatar VARCHAR(16);
  DECLARE _is_support INT DEFAULT 0 ;
  DECLARE _domain VARCHAR(256);
  DECLARE _org_name VARCHAR(256);
  DECLARE _domain_id INTEGER;

  DECLARE _entity_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _ntime INT(11); 
  DECLARE _etime INT(11); 

  SELECT UNIX_TIMESTAMP() INTO _ntime;

   SELECT id FROM entity e INNER JOIN(drumate d) USING(id) WHERE 
    e.id=_key  INTO _id;

   SELECT id FROM entity e INNER JOIN(drumate d) USING(id) WHERE 
    d.email=_key  AND  _id IS NULL INTO _id;


  SELECT _id INTO _entity_id;

  SELECT o.id
  FROM  yp.drumate d  
  INNER JOIN yp.organisation o ON o.domain_id= d.domain_id
  WHERE d.id =  _id AND  d.domain_id > 1  INTO _entity_id; 

  SELECT  IF(s.conf_value=o.domain_id, 1, 0)
    FROM organisation o 
    INNER JOIN drumate d ON d.domain_id=o.domain_id 
    INNER JOIN sys_conf s ON s.conf_key= 'support_domain' 
    WHERE d.id=_id
  INTO _is_support;
  
  IF _id IS NULL OR _id = '' OR _key = '' THEN
    SET _id = 'ffffffffffffffff';
  END IF;
  -- SELECT photo FROM `profile` WHERE drumate_id=_id and area='public' INTO _avatar;
  SELECT
    ee.id,
    IF(ee.id = get_sysconf('guest_id'), 1, 0) isGuest,
    ee.id as hub_id,
    dr.username AS ident,
    dr.username,
    db_name,
    home_dir,
    ee.home_id,
    dr.remit AS remit,
    mtime,
    ctime,
    dd.name AS domain,
    dd.id AS domain_id,
    oo.name AS organization,
    lang,
    avatar,
    status,
    profile,
    settings,
    -- disk_usage(ee.id) AS disk_usage,
    get_quota(ee.id) quota,
    firstname,
    lastname,
    fullname,
    IFNULL(JSON_value(dr.profile, "$.profile_type"),'normal')  profile_type,
    _is_support is_support
    FROM entity ee 
      INNER JOIN drumate dr ON ee.id=dr.id
      INNER JOIN domain dd ON dd.id=ee.dom_id
      INNER JOIN privilege pr ON dr.id=pr.uid
      INNER JOIN organisation oo ON ee.dom_id = oo.domain_id 
    WHERE ee.id=_id GROUP BY(ee.id);
END $

DELIMITER ;