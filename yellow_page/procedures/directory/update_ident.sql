DELIMITER $

DROP PROCEDURE IF EXISTS `update_ident`$
CREATE PROCEDURE `update_ident`(
  IN _id VARBINARY(16),
  IN _new_ident VARCHAR(60)
)
BEGIN
  DECLARE _type VARCHAR(40);
  DECLARE _domain VARCHAR(80);
  DECLARE _domain_id INTEGER;
  DECLARE _domain_ident VARCHAR(80);
  SELECT e.type, d.name, d.id FROM entity e INNER JOIN domain d 
    ON e.dom_id=d.id 
    WHERE e.id = _id INTO _type, _domain, _domain_id;

  SELECT ident FROM organisation WHERE domain_id=_domain_id INTO _domain_ident;

  START TRANSACTION;
    UPDATE entity SET 
      ident=_new_ident, 
      vhost=CONCAT(_new_ident, '-', _domain_ident, '.', main_domain()) 
    WHERE ident=_id;

    UPDATE vhost SET fqdn=CONCAT(_new_ident, '.', _domain) 
      WHERE id = _id;
    IF _type = "drumate" THEN
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
      e.homepage,
      e.db_name, 
      e.db_host, 
      e.fs_host, 
      e.home_dir
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
      e.homepage,
      e.db_name, 
      e.db_host, 
      e.fs_host, 
      e.home_dir
    FROM enit e 
      INNER JOIN drumate d ON e.id=d.id
      INNER JOIN vhost v ON e.id=v.id
    WHERE id=_id;
  END IF;
END$


DELIMITER ;
