-- =========================================================
-- get_visitor
-- =========================================================
DELIMITER $

DROP PROCEDURE IF EXISTS `change_vhost`$
CREATE PROCEDURE `change_vhost`(
  _id varchar(16),
  _ident  varchar(512)
)
BEGIN
  DECLARE _exists INT(8);

  SELECT d.name FROM 
    domain d INNER JOIN vhost v ON d.id=v.dom_id WHERE v.id=_id INTO @domain;
  IF @domain IS NOT NULL THEN 
    SET @fqdn=CONCAT(_ident, '.', @domain);
    SELECT count(*) FROM vhost WHERE fqdn=@fqdn INTO _exists;
    IF _exists = 0 THEN 
      UPDATE vhost SET fqdn=@fqdn WHERE id=_id;
    END IF;
  END IF;

END$

DELIMITER ;

