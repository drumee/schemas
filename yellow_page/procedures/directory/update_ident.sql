DELIMITER $

DROP PROCEDURE IF EXISTS `update_ident`$
CREATE PROCEDURE `update_ident`(
  IN _id VARBINARY(16),
  IN _new_ident VARCHAR(60)
)
BEGIN
  DECLARE _old_ident VARCHAR(60);
  DECLARE _type VARCHAR(40);
  DECLARE _domain VARCHAR(80);
  SELECT d.name FROM entity e INNER JOIN domain d 
    ON e.dom_id=d.id 
    WHERE e.id = _id INTO _domain;
  SELECT ident, `type` FROM entity WHERE 
    id = _id INTO _old_ident, _type;

  START TRANSACTION;
    UPDATE entity SET 
      ident=_new_ident, 
      vhost=CONCAT(_new_ident, '.', _domain) 
    WHERE ident=_old_ident;

    UPDATE vhost SET fqdn=CONCAT(_new_ident, '.', _domain) 
      WHERE fqdn=CONCAT(_old_ident, '.', _domain);
    IF _type = "hub" THEN
      UPDATE hub SET hubname=_new_ident WHERE id=_id;
    ELSIF _type = "drumate" THEN
      UPDATE drumate SET username=_new_ident WHERE id=_id;
    END IF;
  COMMIT;

  IF _type = "hub" THEN
    SELECT 
      e.id, 
      e.mtime, 
      e.status, 
      e.type, 
      e.area,
      v.fqdn vhost, 
      e.headline, 
      e.homepage,
      e.layout, 
      e.db_name, 
      e.db_host, 
      e.fs_host, 
      e.home_dir,
      e.settings, 
      h.hubname as ident, 
      h.permission, 
      h.dmail, 
      h.photo, 
      h.profile
    FROM entity e 
        INNER JOIN hub h ON e.id=h.id
        INNER JOIN vhost v ON e.id=v.id
    WHERE e.id = _id;
  ELSEIF _type = "drumate" THEN
    SELECT
      e.id, 
      e.mtime, 
      e.status, 
      e.type, 
      e.area,
      v.fqdn vhost, 
      e.headline, 
      e.homepage,
      e.layout, 
      e.db_name, 
      e.db_host, 
      e.fs_host, 
      e.home_dir,
      e.settings, 
      d.username AS ident, 
      d.permission, 
      d.dmail, 
      d.photo, 
      d.profile
    FROM enit e 
      INNER JOIN drumate d ON e.id=d.id
      INNER JOIN vhost v ON e.id=v.id
    WHERE id=_id;
  END IF;
END$


DELIMITER ;
