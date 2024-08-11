DELIMITER $
DROP FUNCTION IF EXISTS `vhost_next`$
CREATE FUNCTION `vhost_next`(
  _key VARCHAR(1024)
)
RETURNS VARCHAR(1024) DETERMINISTIC
BEGIN
  DECLARE _vhost VARCHAR(1024);

  IF _key REGEXP '^(.+)\\\.(.+)' THEN
    SELECT _key INTO _vhost;
  ELSE
    SELECT v.fqdn FROM entity e 
      INNER JOIN vhost v ON v.id=e.id
      INNER JOIN domain d ON e.dom_id=d.id 
      INNER JOIN hub h ON h.id=e.id
      WHERE h.hubname=_key OR e.id=_key OR e.db_name=_key LIMIT 1 INTO _vhost;
  END IF;

  RETURN _vhost;
END$


DELIMITER ;