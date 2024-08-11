DELIMITER $
DROP PROCEDURE IF EXISTS `migrate_drumates`$
CREATE PROCEDURE `migrate_drumates`(
  -- IN _hub_db VARCHAR(80),
  -- IN _hub_id VARCHAR(80),
  -- IN _ident VARCHAR(80),
  -- IN _area VARCHAR(16),
  -- IN _oid  VARCHAR(16),
  IN _args JSON
)
BEGIN
  DECLARE _tmp_id VARCHAR(50);
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
  -- SELECT id FROM yp.entity WHERE ident=_ident INTO _existing;
  -- IF _existing IS NULL THEN 
  SELECT id FROM yp.entity WHERE ident=_ident INTO _existing;
  -- SELECT   _ident, _existing;
  IF _existing IS NULL THEN 
    START TRANSACTION;
    CALL drumate_create('', utils.read_json_object(_args, 'profile'));
    SELECT id FROM yp.entity WHERE id=_ident INTO _tmp_id;
    IF _tmp_id IS NOT NULL THEN 
      UPDATE drumate SET id=_id, fingerprint=utils.read_json_object(_args, 'fingerprint') WHERE id=_tmp_id;
      UPDATE yp.entity SET 
        id=_id, 
        status='active', 
        area='personal', 
        -- db_name=utils.read_json_object(_args, 'db_name'), 
        home_dir=utils.read_json_object(_args, 'home_dir'), 
        ident=_ident,
        vhost=_fqdn 
      WHERE id = _tmp_id;
      UPDATE share_box SET owner_id = _id WHERE owner_id = _tmp_id;
      UPDATE vhost SET id = _id WHERE id = _tmp_id;
    END IF;
    IF _rollback THEN
      ROLLBACK;
      SELECT 1 as failed;
    ELSE
      COMMIT;
      SELECT id, db_name, ident, home_dir FROM yp.entity WHERE id=_id;
    END IF;
  ELSE
    SELECT id, db_name, ident, home_dir FROM yp.entity WHERE id=_existing;
  END IF;
END$

DELIMITER ;