DELIMITER $
DROP FUNCTION IF EXISTS `vhost`$
CREATE FUNCTION `vhost`(
  _key VARCHAR(1024)
)
RETURNS VARCHAR(1024) DETERMINISTIC
BEGIN
  DECLARE _vhost VARCHAR(1024);

  IF _key REGEXP '^(.+)\\\.(.+)' THEN
    SELECT _key INTO _vhost;
  ELSE
    SELECT v.fqdn FROM entity e 
      INNER JOIN yp.domain d ON d.id = e.dom_id 
      LEFT JOIN yp.vhost v ON v.id = e.id
      LEFT JOIN yp.entity dr ON e.id = dr.id AND e.area='personal'
      LEFT JOIN yp.entity h ON e.id = h.id AND e.area IN('private', 'public', 'share','dmz','restricted')
      WHERE e.id=_key OR e.db_name=_key GROUP BY (v.id) LIMIT 1 INTO _vhost;
  END IF;

  RETURN _vhost;
END$


DELIMITER ;