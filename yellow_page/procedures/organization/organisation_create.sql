
DELIMITER $
DROP PROCEDURE IF EXISTS `organisation_create`$

CREATE PROCEDURE `organisation_create`(
  IN _args JSON,
  IN _metadata JSON
)
BEGIN
  DECLARE _id VARCHAR(16) DEFAULT NULL;
  DECLARE _owner_id VARCHAR(16) DEFAULT NULL;
  DECLARE _name VARCHAR(512);
  DECLARE _master_domain VARCHAR(1024);
  DECLARE _user_domain VARCHAR(1024);
  DECLARE _ident VARCHAR(80);
  DECLARE _domain_id INT(11) DEFAULT 0;
  DECLARE _rollback BOOLEAN DEFAULT 0;

  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN
    SET _rollback = 1;  
    GET DIAGNOSTICS CONDITION 1 
      @sqlstate = RETURNED_SQLSTATE, 
      @errno = MYSQL_ERRNO, 
      @message = MESSAGE_TEXT;
  END;

  START TRANSACTION;

  SELECT JSON_VALUE(_args, "$.owner_id") INTO _owner_id;
  SELECT JSON_VALUE(_args, "$.ident") INTO _ident;
  SELECT IFNULL(JSON_VALUE(_args, "$.name"), _ident) INTO _name;


  SELECT id  FROM yp.entity WHERE `type`='hub' AND area='pool' 
    AND JSON_VALUE(settings, "$.pool_state") = "clean" LIMIT 1 
  INTO _id ; 

  IF _id IS NULL THEN 
    SET _rollback = 1;
    SET @message = "POOL_EMPTY";
    SET @sqlstate = "0";
    SET @errno = 0;
  END IF;

  IF _ident IS NULL THEN 
    SELECT uniqueId() INTO _ident;
  END IF;

  SELECT domain_id FROM privilege WHERE `uid`=_owner_id INTO _domain_id;

  IF _domain_id = 0 THEN
    CALL domain_create(_ident);
    SELECT CONCAT(_ident,".", main_domain()) INTO _user_domain;
    SELECT id FROM domain WHERE `name` = _user_domain INTO _domain_id;
  ELSE 
    SELECT `name` FROM domain WHERE id = _domain_id INTO _user_domain;
    SELECT REGEXP_REPLACE(`name`, CONCAT("\.", main_domain(), "$") , "") 
      FROM domain WHERE id = _domain_id INTO _ident;
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
    _user_domain,
    _ident, 
    _owner_id, 
    _metadata
  );

  UPDATE entity SET 
    `area` = 'public', 
    `dom_id` =_domain_id, 
    `type` = 'organization', 
    `status`='active', 
    `homepage` = "",
    ctime = UNIX_TIMESTAMP()
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
    _user_domain,
    9999999, 
    null,
    _domain_id,
    null; 

  INSERT INTO vhost(`fqdn`,`id`,`dom_id`)
    SELECT `name`, _id, id
  FROM domain WHERE id=_domain_id;
  UPDATE entity SET `type`='organization' WHERE id=_id;
  CALL  my_organisation(_owner_id);
  IF _rollback THEN
    ROLLBACK;
    SELECT 1 failed, @sqlstate `sqlstate`, @errno `errno`, @message `error`;
  ELSE
    SELECT 0 failed, _domain_id domain_id, _id id, _user_domain user_domain;
    COMMIT;
  END IF;

END$
