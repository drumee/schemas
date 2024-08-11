DELIMITER $
DROP PROCEDURE IF EXISTS `migrate_create_hub`$
CREATE PROCEDURE `migrate_create_hub`(
  -- IN _hub_db VARCHAR(80),
  -- IN _hub_id VARCHAR(80),
  -- IN _ident VARCHAR(80),
  -- IN _area VARCHAR(16),
  -- IN _oid  VARCHAR(16),
  IN _args JSON
)
BEGIN
  DECLARE _new_id VARCHAR(50);
  DECLARE _id VARCHAR(50);
  DECLARE _oid VARCHAR(50);
  DECLARE _ident VARCHAR(500);
  DECLARE _domain VARCHAR(500);
  DECLARE _odb VARCHAR(50);
  DECLARE _existing VARCHAR(50);
  DECLARE _fqdn VARCHAR(1024);  /* Fully Qualified Domain Name*/
  DECLARE _rollback BOOL DEFAULT 0;   
  -- DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET _rollback = 1;  

  SELECT utils.domain_name() INTO _domain;
  SELECT utils.read_json_object(_args, 'owner_id') INTO _oid;
  SELECT utils.read_json_object(_args, 'id') INTO _id;
  SELECT utils.read_json_object(_args, 'ident') INTO _ident;
  
  SELECT id FROM yp.entity WHERE id=_id INTO _existing;
  SELECT CONCAT(utils.read_json_object(_args, 'ident'), '.', _domain) INTO _fqdn;
  IF _existing IS NULL THEN 
    START TRANSACTION;
    SELECT id FROM yp.entity WHERE type='hub' AND area='pool' LIMIT 1 INTO _new_id;

    -- SELECT _fqdn, _db_name, utils.read_json_object(_args, 'id'), utils.read_json_object(_args, 'owner_id'),
    -- utils.read_json_object(_args, 'name');
    --   _name,
    --   "Key words", yp.get_dmail(_ident), _profile);
    UPDATE yp.entity SET 
      id=_id, 
      status=utils.read_json_object(_args, 'status'), 
      area=utils.read_json_object(_args, 'area'), 
      -- db_name=utils.read_json_object(_args, 'db_name'), 
      home_dir=utils.read_json_object(_args, 'home_dir'), 
      ident=_ident,
      vhost=_fqdn 
    WHERE id = _new_id;

    REPLACE INTO yp.vhost VALUES (null, _fqdn, _id, _domain);
    REPLACE INTO yp.hub (
      `id`, 
      `owner_id`, 
      `origin_id`, 
      `name`, 
      `keywords`, 
      `dmail`
    )
    VALUES (
      _id, 
      _oid,
      _oid,
      utils.read_json_object(_args, 'user_filename'),
      "Key words", 
      yp.get_dmail(_ident)
    );
    IF _rollback THEN
      ROLLBACK;
      SELECT 1 as failed;
    ELSE
      COMMIT;
      SELECT id, db_name, ident, home_dir FROM yp.entity WHERE id=_id;
    END IF;
  ELSE
    SELECT id, db_name, ident, home_dir FROM yp.entity WHERE id=_id;
    SELECT concat(ident, '.', utils.domain_name()) FROM entity WHERE id=_id INTO _fqdn;
    REPLACE INTO yp.vhost VALUES (null, _fqdn, _id, _domain);

  END IF;
  SELECT db_name FROM entity WHERE id=_oid INTO _odb;
  SET @s = CONCAT("call ", _odb, ".join_hub(", quote(_id), ")");
  PREPARE stmt FROM @s;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;
END$

DELIMITER ;