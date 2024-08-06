DELIMITER $

DROP PROCEDURE IF EXISTS `vhost_exists`$
CREATE PROCEDURE `vhost_exists`(
  IN _key VARCHAR(1000)
)
BEGIN
  SELECT * FROM vhost WHERE fqdn = _key;
END$
