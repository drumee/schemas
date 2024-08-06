


DELIMITER $
DROP PROCEDURE IF EXISTS `organisation_add`$
CREATE PROCEDURE `organisation_add`(
  _owner_id VARCHAR(16),
  _name VARCHAR(512) ,
  _link VARCHAR(1024) ,
  _ident VARCHAR(80),
  _domain_id INT(11) , 
  _metadata JSON
)
BEGIN
  DECLARE _id VARCHAR(16);


  SELECT id  FROM yp.entity WHERE `type`='hub' AND area='pool' 
    AND JSON_VALUE(settings, "$.pool_state") = "clean" LIMIT 1 
  INTO _id ; 

  IF _link IN ('') THEN 
    SELECT _id INTO  _link;
  END IF;

  INSERT INTO organisation(
    `id`,
    `domain_id`,
    `name`,
    `link`,
    `ident`,
    `owner_id`,
    `metadata`
  )
  VALUES(
    _id,
    _domain_id,
    _name,
    _link,
    _ident, 
    _owner_id, 
    _metadata
  );

  UPDATE entity SET 
    `area` = 'public', 
    `dom_id` =_domain_id, 
    `type` = 'organization', 
    `status`='active', 
    `homepage` = ""
  WHERE id = _id;

	INSERT INTO yp.hub (
    `id`,
    `owner_id`, 
    `origin_id`, 
    `name`, 
    `serial`,
    `hubname`, 
    `domain_id`, 
    `profile`
  )
	SELECT _id,
    _owner_id,
    _owner_id,
    _link,
    9999999, 
    null,
    _domain_id,
    null; 

  INSERT INTO vhost(`fqdn`,`id`,`dom_id`)
    SELECT link, id, domain_id
  FROM organisation WHERE id=_id;

  INSERT INTO subscription (payment_id, entity_id, stime,etime,ctime,mode)
  SELECT yp.uniqueId(), _id,  UNIX_TIMESTAMP(), UNIX_TIMESTAMP() +(30*24*3600),UNIX_TIMESTAMP(), 'free' ;

  CALL  my_organisation(_owner_id);

END$
DELIMITER ;