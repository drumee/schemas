
DELIMITER $
DROP PROCEDURE IF EXISTS `drumate_create`$
CREATE PROCEDURE `drumate_create`(
  IN _pw VARCHAR(225),   
  IN _profile TEXT
)
BEGIN
   
  DECLARE _firstname VARCHAR(255);
  DECLARE _lastname  VARCHAR(255);    
  DECLARE _email     VARCHAR(500);
  DECLARE _mobile    VARCHAR(30) ;     
  DECLARE _address   VARCHAR(500);
  DECLARE _city      VARCHAR(80);  
  DECLARE _country   VARCHAR(80);  
  DECLARE _dob       VARCHAR(80);
  DECLARE _domain    VARCHAR(500);
  DECLARE _domain_id INTEGER UNSIGNED;

  DECLARE _home_dir     VARCHAR(1024);
  DECLARE _home_id      VARCHAR(16);
  DECLARE _dru_fqdn     VARCHAR(1024);
  DECLARE _dru_id       VARCHAR(16);
  DECLARE _dru_lang     VARCHAR(16);
  DECLARE _dru_db       VARCHAR(50);
  DECLARE _category     VARCHAR(50);
  DECLARE _now          INT(11);
  DECLARE _fingerprint  VARCHAR(255);  
  DECLARE _username     VARCHAR(80);
  DECLARE _privilege    TINYINT(4) DEFAULT 3;
  DECLARE _quota        JSON;
  DECLARE _uniqueid     VARCHAR(16);
  DECLARE _quota_key    VARCHAR(16);
  DECLARE _icon VARCHAR(1024) DEFAULT "/-/images/logo/desk.jpg";

  DECLARE _rollback BOOL DEFAULT 0;   
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN
    SET _rollback = 1;  
    GET DIAGNOSTICS CONDITION 1 
      @sqlstate = RETURNED_SQLSTATE, 
      @errno = MYSQL_ERRNO, 
      @text = MESSAGE_TEXT;
    SET @full_error = CONCAT("ERROR: ", @errno, " (", @sqlstate, "): ", @text);
  END;

  SELECT UNIX_TIMESTAMP() INTO _now;
  SELECT JSON_VALUE(_profile, "$.domain") INTO _domain;
  SELECT JSON_VALUE(_profile, "$.domain_id") INTO _domain_id;
  SELECT JSON_VALUE(_profile, "$.username") INTO _username;
  SELECT JSON_VALUE(_profile, "$.firstname") INTO _firstname;
  SELECT JSON_VALUE(_profile, "$.lastname") INTO _lastname; 
  SELECT JSON_VALUE(_profile, "$.lang") INTO _dru_lang; 
  SELECT JSON_VALUE(_profile, "$.email") INTO _email; 
  SELECT JSON_VALUE(_profile, "$.mobile") INTO _mobile; 
  SELECT JSON_VALUE(_profile, "$.address") INTO _address; 
  SELECT JSON_VALUE(_profile, "$.city") INTO _city; 
  SELECT JSON_VALUE(_profile, "$.country") INTO _country; 
  SELECT JSON_VALUE(_profile, "$.dob") INTO _dob;  

  SELECT strip_accents(_username) INTO  _username;

  IF _domain_id IS NULL THEN 
    IF _domain IS NULL THEN 
      SELECT get_sysconf('domain_name') INTO _domain;
    END IF;

    SELECT id FROM domain WHERE `name`= _domain INTO _domain_id;
    IF _domain_id IS NULL THEN
      SELECT 1 INTO _domain_id;
    END IF;
  ELSE 
    SELECT name FROM domain WHERE id=_domain_id INTO _domain;
  END IF;
  IF _domain IS NULL THEN
    SELECT get_sysconf('domain_name' ) INTO _domain;
    SELECT 1 INTO _domain_id;
  END IF;

  SELECT CAST(IFNULL(JSON_VALUE(_profile, "$.privilege"), 1) AS INTEGER) INTO _privilege;  
  SELECT IFNULL(JSON_VALUE(_profile, "$.category"), 'user') INTO _category;  
  
  SELECT sha2(_pw, 512) INTO _fingerprint;

  CALL pickupEntity('drumate', _dru_id, _dru_db);
  SELECT unique_username(_username, _domain) INTO _username;
  SELECT CONCAT(_username, 
    IF(_domain = main_domain(), '-u.', '-u-'), _domain) INTO _dru_fqdn;

  START TRANSACTION;
  IF _dru_id IS NOT NULL AND _domain_id IS NOT NULL THEN
    INSERT INTO drumate(
      id, username, profile, fingerprint, remit, domain_id)
    VALUES(
      _dru_id, _username, _profile, _fingerprint,  0, _domain_id
    );

    INSERT IGNORE INTO privilege (uid, privilege, domain_id)
    VALUES(_dru_id, _privilege, _domain_id)
    ON DUPLICATE KEY UPDATE privilege=_privilege;

    SELECT conf_value FROM sys_conf WHERE conf_key='icon' INTO _icon;

    UPDATE entity SET 
      area='personal', 
      status='active', 
      type='drumate', 
      dom_id =_domain_id, 
      ctime=UNIX_TIMESTAMP(),
      mtime=UNIX_TIMESTAMP(),
      accessibility='personal',
      icon=_icon
    WHERE id=_dru_id;
    SELECT home_dir, home_id FROM entity WHERE id=_dru_id INTO _home_dir, _home_id;
    INSERT INTO vhost VALUES (null, _dru_fqdn, _dru_id, _domain_id);

    SET @s = CONCAT("CALL `", _dru_db, "`.permission_grant('*', ?, 0, 63, 'system', '')");
    PREPARE stmt FROM @s;
    EXECUTE stmt USING _dru_id;
    DEALLOCATE PREPARE stmt;

    SET @s = CONCAT("CALL `", _dru_db, "`.permission_grant('*', '*', 0, 0, 'system', 'personal-access')");
    PREPARE stmt FROM @s;
    DEALLOCATE PREPARE stmt;

    SET @st1 = CONCAT("CALL ", _dru_db, ".mfs_trash_init()");
    PREPARE stmt1 FROM @st1;
    EXECUTE stmt1;           
    DEALLOCATE PREPARE stmt1;

    SET @st1 = CONCAT("CALL ", _dru_db, ".mfs_chat_init()");
    PREPARE stmt1 FROM @st1;
    EXECUTE stmt1;           
    DEALLOCATE PREPARE stmt1; 

    SELECT  uniqueId() INTO _uniqueid;
    SELECT  uniqueId() INTO @wicket;
    SET @st1 = CONCAT("CALL ", _dru_db, ".desk_create_hub(?,?)");
    PREPARE stmt1 FROM @st1;
    EXECUTE stmt1 USING  
      JSON_OBJECT("hostname", _uniqueid, "domain_id", _domain_id, "filename",@wicket, "area", 'dmz', "owner_id", _dru_id),
      JSON_OBJECT("is_wicket",1);        
    DEALLOCATE PREPARE stmt1;

  ELSE
    ROLLBACK;
    SELECT 2 failed, "EMPTY_FACTORY" AS reason;
  END IF;

  IF _rollback THEN
    ROLLBACK;
    SELECT 1 as failed, _dru_db db_name, @full_error AS reason;
  ELSE
    COMMIT;
  END IF;

  SELECT 
    JSON_OBJECT(
      'id', _dru_id, 
      'uid', _dru_id, 
      'username', _username, 
      'db_name', _dru_db, 
      'vhost', _dru_fqdn,
      'domain_id', _domain_id,
      'domain_name', _domain,
      'home_dir', _home_dir, 
      'home_id', _home_id
    ) drumate,
    _rollback failed;
END$
