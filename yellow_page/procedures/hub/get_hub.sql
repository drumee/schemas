DELIMITER $


-- =========================================================
-- get_hub
-- =========================================================
DROP PROCEDURE IF EXISTS `get_hub`$
CREATE PROCEDURE `get_hub`(
  IN _key VARCHAR(255) CHARACTER SET ascii
)
BEGIN
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _hub_db VARCHAR(40);
  DECLARE _fqdn VARCHAR(1024);
  DECLARE _vhost VARCHAR(1024);
  DECLARE _filesize FLOAT;
  DECLARE _type VARCHAR(1024);
  DECLARE _domain VARCHAR(1024);
  DECLARE _exists BOOLEAN DEFAULT 1;
  DECLARE _org_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _home_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _org_name VARCHAR(512);
  DECLARE _entry_host VARCHAR(1024) DEFAULT 'george';

  SELECT e.home_id, o.link, o.domain_id, o.name, v.fqdn, e.id, e.type
    FROM vhost v
    INNER JOIN entity e ON v.id=e.id
    INNER JOIN organisation o ON o.domain_id=e.dom_id
  WHERE v.fqdn=_key  LIMIT 1
  INTO _home_id, _domain, _org_id, _org_name, _vhost, _hub_id, _type;

  IF _hub_id IS NULL  THEN
    SELECT e.home_id, o.link, o.domain_id, o.name, v.fqdn, e.id, e.type
      FROM vhost v
      INNER JOIN entity e ON v.id=e.id
      INNER JOIN organisation o ON o.domain_id=e.dom_id
    WHERE  e.id=_key  AND  _hub_id IS NULL  LIMIT 1 
    INTO _home_id, _domain, _org_id, _org_name, _vhost, _hub_id, _type;
  END IF;

  IF _hub_id IS NULL  THEN
    SELECT  e.home_id, o.link, o.domain_id, o.name, v.fqdn, e.id, e.type
      FROM vhost v
      INNER JOIN entity e ON v.id=e.id
      INNER JOIN organisation o ON o.domain_id=e.dom_id
    WHERE  e.db_name=_key   AND  _hub_id IS NULL LIMIT 1
    INTO _home_id, _domain, _org_id, _org_name, _vhost, _hub_id, _type;
  END IF;

  IF _hub_id IS NULL  THEN
    SELECT conf_value FROM sys_conf WHERE conf_key='entry_host' INTO _entry_host;
    SELECT id, fqdn FROM vhost WHERE id=_entry_host
      INTO _hub_id, _fqdn;
    SELECT 0 INTO _exists;
  END IF;

  IF(SELECT count(*) FROM yp.disk_usage WHERE hub_id=_hub_id) = 0 AND _hub_id IS NOT NULL THEN 
    INSERT INTO yp.disk_usage VALUES(null, _hub_id, 0);
  END IF;

  SELECT size FROM disk_usage WHERE hub_id=_hub_id INTO _filesize;

  SELECT
    e.id,
    e.id as oid,
    e.id AS hub_id,
    h.hubname,
    _exists AS `exists`,
    _org_id AS org_id,
    _home_id AS home_id,
    _org_name AS org_name,
    _domain AS org_home,
    _vhost as vhost,
    _domain AS domain,
    h.owner_id,
    main_domain() AS master_domain,
    db_name,
    db_host,
    fs_host,
    home_dir,
    `type`,
    area,
    default_lang,
    status,
    ctime,
    mtime,
    IF(_exists, COALESCE(h.name, d.fullname), _org_name) AS `name`,
    e.headline AS keywords,
    homepage,
    _vhost AS hostname,
    icon,
    settings,
    COALESCE(d.profile, h.profile) `profile`,
    IF(_exists, _filesize, 0) as disk_usage
  FROM entity e 
    LEFT JOIN hub h ON h.id = e.id 
    LEFT JOIN drumate d ON d.id = e.id 
    WHERE e.id=_hub_id;
END$

DELIMITER ;