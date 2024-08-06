DELIMITER $


-- =========================================================
-- get_hub
-- =========================================================
DROP PROCEDURE IF EXISTS `get_entity`$
CREATE PROCEDURE `get_entity`(
  IN _key VARCHAR(255)
)
BEGIN
  DECLARE _entity_id VARBINARY(16);
  DECLARE _hub_db VARCHAR(40);
  DECLARE _fqdn VARCHAR(1024);
  DECLARE _filesize FLOAT;
  DECLARE _title VARCHAR(1024);
  DECLARE _keywords VARCHAR(1024);
  DECLARE _domain VARCHAR(1024);
  DECLARE _vhost VARCHAR(1024);
  DECLARE _master_domain VARCHAR(1024);
  


  SELECT vhost(_key) INTO _vhost;
  IF _vhost IS NULL THEN
    SELECT e.id, d.name, main_domain()
      FROM drumate dr 
      INNER JOIN entity e ON dr.id=e.id
      INNER JOIN domain d ON d.id=e.dom_id
      WHERE e.id=_key 
      INTO _entity_id, _domain, _master_domain;
  ELSE
    SELECT e.id, fqdn, d.name, main_domain()
      FROM vhost v INNER JOIN(entity e, domain d) 
      ON e.id=v.id and d.id=e.dom_id
      WHERE fqdn=_vhost 
      INTO _entity_id, _fqdn, _domain, _master_domain;
  END IF;

  SELECT
    e.id,
    e.id as oid,
    e.id AS hub_id,
    e.home_id AS home_id,
    -- ident,
    _fqdn as vhost,
    _fqdn AS dhost,
    _domain AS domain,
    _master_domain AS master_domain,
    db_name,
    db_host,
    fs_host,
    home_dir,
    `type`,
    area,
    status,
    ctime,
    mtime,
    _fqdn AS hostname,
    settings,
    _filesize as disk_usage
  FROM entity e 
    LEFT JOIN drumate d USING(id)
  WHERE e.id=_entity_id;
END$

DELIMITER $