DELIMITER $

DROP PROCEDURE IF EXISTS `drumate_change_username`$
CREATE PROCEDURE `drumate_change_username`(
  IN _id      VARBINARY(16),
  IN _username   VARCHAR(80)
)
BEGIN
  DECLARE _domain_name    VARCHAR(500);
  DECLARE _fqdn    VARCHAR(500);
  
  UPDATE drumate SET username = _username  WHERE id=_id;
  SELECT id, profile, firstname, lastname, quota, home_dir 
    FROM drumate INNER JOIN entity USING (id) WHERE id = _id;

  SELECT d.name FROM domain d INNER JOIN drumate dr ON dr.domain_id = d.id 
    WHERE dr.id=_id INTO _domain_name;

  SELECT CONCAT(_username, 
    IF(_domain_name = main_domain(), '-u.', '-u-'), _domain_name) INTO _fqdn;

  UPDATE vhost set fqdn=_fqdn WHERE id=_id; 

END$

DELIMITER ;