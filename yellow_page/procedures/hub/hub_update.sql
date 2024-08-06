DELIMITER $
DROP PROCEDURE IF EXISTS `hub_update`$
CREATE PROCEDURE `hub_update`(
  IN _id VARCHAR(16),
  IN _ident VARCHAR(40),
  IN _name VARCHAR(40),
  IN _headline VARCHAR(255),
  IN _keywords VARCHAR(1024),
  IN _permission TINYINT(4)
)
BEGIN
  DECLARE _type VARCHAR(40);
  DECLARE _cur_ident VARCHAR(40);
  DECLARE _cur_oid VARCHAR(20);

  SELECT ident, area_oid FROM site_csv WHERE id=_id INTO _cur_ident, _cur_oid;

  START TRANSACTION;
    UPDATE entity SET headline=_headline, ident=_ident,
      vhost=yp.get_vhost(_ident), mtime=unix_timestamp() WHERE id=_id;

    UPDATE hub SET keywords=_keywords, name=_name, permission=_permission WHERE id=_id;

    IF _ident != _cur_ident AND _cur_ident !='' THEN
      UPDATE `vhost` SET fqdn=yp.get_vhost(_ident) WHERE fqdn=yp.get_vhost(_cur_ident);
    END IF;
    SELECT * FROM site_view WHERE id=_id;
  COMMIT;
END$
DELIMITER ;
