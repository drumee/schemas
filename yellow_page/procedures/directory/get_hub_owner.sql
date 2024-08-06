
DELIMITER $
DROP PROCEDURE IF EXISTS `get_hub_owner`$
CREATE PROCEDURE `get_hub_owner`(
  IN _vhost VARCHAR(255)
)
BEGIN
  DECLARE _hub_id VARCHAR(16);
  DECLARE _ident VARCHAR(128);
  DECLARE _area VARCHAR(128);
 
  SELECT vhost(_vhost) INTO _vhost;

  SELECT id, ident, area FROM vhost INNER JOIN entity using(id) WHERE fqdn=_vhost 
    INTO _hub_id, _ident, _area;


  SELECT
    h.id AS hub_id,
    _ident AS ident,
    _area AS area,
    owner_id,
    d.firstname,
    JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.email')) AS email,
    d.lastname
  FROM hub h INNER JOIN (yp.drumate d) ON 
    h.owner_id=d.id  WHERE h.id=_hub_id;
END$
DELIMITER ;