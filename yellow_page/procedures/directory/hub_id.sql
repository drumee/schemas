DELIMITER $
DROP FUNCTION IF EXISTS `hub_id`$
CREATE FUNCTION `hub_id`(
  _key VARCHAR(1024)
)
RETURNS VARCHAR(16) DETERMINISTIC
BEGIN
  DECLARE _res VARCHAR(16);
  DECLARE _vhost VARCHAR(1024);

  IF _key NOT REGEXP '^(.+)\\\.(.+)' THEN
    SELECT concat(hubname, '.', yp.get_domain_name(hubname)) FROM hub 
      WHERE hubname=_key OR id=_key INTO _vhost;
  END IF;

  SELECT id FROM vhost INNER JOIN entity using(id) 
    WHERE fqdn=_vhost OR fqdn=CONCAT(_key, '.', yp.get_domain_name(_key)) INTO _res;
  IF _res IS NULL THEN 
    SELECT e.id FROM entity e INNER JOIN domain d on 
    e.dom_id=d.id WHERE e.id=_key INTO _res;
  END IF;
  RETURN _res;
END$
DELIMITER ;
