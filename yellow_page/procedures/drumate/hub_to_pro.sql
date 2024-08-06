DELIMITER $

DROP PROCEDURE IF EXISTS `drumate_hub_to_pro`$
CREATE PROCEDURE `drumate_hub_to_pro`(
  IN _uid          VARCHAR(16) CHARACTER SET ascii,
  IN _domain_id INT,
  IN _privilege TINYINT(4)
)
BEGIN

  DECLARE  _link  VARCHAR(1024); 
  DECLARE  _org_id    VARCHAR(16) CHARACTER SET ascii;
  
  SELECT link, id  FROM yp.organisation 
  WHERE domain_id =  _domain_id INTO _link,_org_id;

 --  domain id change in drumate ,hub ,vhost

  UPDATE yp.hub SET domain_id = _domain_id  WHERE  owner_id = _uid;
  UPDATE yp.drumate SET domain_id = _domain_id  WHERE  id = _uid;
  UPDATE yp.vhost  SET dom_id = _domain_id  
  WHERE id IN (SELECT id  FROM  yp.hub WHERE  owner_id = _uid) ;

  UPDATE yp.vhost  SET dom_id = _domain_id  
  WHERE id  = _uid ;

--  fqdn change

  SELECT fqdn ,SUBSTRING_INDEX(fqdn , '.', 1) ,_link,
  CONCAT ( SUBSTRING_INDEX(fqdn , '.', 1), '.',_link)
  FROM yp.vhost 
  WHERE dom_id = _domain_id AND id != _org_id;

  UPDATE yp.vhost 
  SET fqdn =CONCAT ( SUBSTRING_INDEX(fqdn , '.', 1), '.',_link)
  WHERE dom_id = _domain_id AND id != _org_id;

END$

DELIMITER ;

