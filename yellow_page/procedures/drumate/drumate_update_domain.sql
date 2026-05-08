DELIMITER $

DROP PROCEDURE IF EXISTS `drumate_change_domain`$
CREATE PROCEDURE `drumate_change_domain`(
  IN _id    VARCHAR(16),
  IN _domain_id INTEGER
)
BEGIN

  UPDATE drumate SET domain_id=_domain_id WHERE id=_id;
  UPDATE vhost SET dom_id=_domain_id WHERE id=_id;
  UPDATE entity SET dom_id=_domain_id WHERE id=_id;

END$

DELIMITER ;
