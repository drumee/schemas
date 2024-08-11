
DELIMITER $

DROP PROCEDURE IF EXISTS `acl_check`$
CREATE PROCEDURE `acl_check`(
  IN _uid VARCHAR(255) CHARACTER SET ascii,
  IN _permission TINYINT(4),
  IN _nodes JSON
)
BEGIN

  -- DECLARE _uid VARCHAR(16);
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _temp_hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _area VARCHAR(16);
  DECLARE _src_db_name VARCHAR(255);
  DECLARE _mfs_root VARCHAR(512);
  -- DECLARE _token VARCHAR(512);

  DECLARE _rid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _i INT(4) DEFAULT 0;

  -- or ident=_key IS GOING TO BE DEPRECATED, as ident 
  -- SELECT id FROM yp.entity WHERE id=_key INTO _uid;

  DROP TABLE IF EXISTS __tmp_ids;
  CREATE TEMPORARY TABLE __tmp_ids(
    `id` varchar(16) CHARACTER SET ascii DEFAULT NULL ,
    `hub_id` varchar(16) CHARACTER SET ascii DEFAULT NULL,
    db_name varchar(90) DEFAULT NULL,
    expiry int(11) ,
    asked  tinyint(4) unsigned DEFAULT 0,
    privilege int(11) 
  ) ENGINE=MEMORY; 

  IF _permission IS NULL OR _permission='' THEN 
    SET _permission = 0;
  END IF;

  WHILE _i < JSON_LENGTH(_nodes) DO 
    SELECT get_json_array(_nodes, _i) INTO @_node;
    SELECT JSON_VALUE(@_node, "$.nid") INTO _rid;
    -- SELECT JSON_VALUE(@_node, "$.token") INTO _token;
    -- SELECT _rid, _token, @_node, JSON_VALUE(@_node, "$.hub_id");
     SELECT JSON_VALUE(@_node, "$.hub_id") INTO _temp_hub_id;
     SELECT id, db_name, area, concat(home_dir, "__storage__/")
      FROM yp.entity WHERE 
      -- if performance cost, consider forcing hub_id to be really id
      id = _temp_hub_id
      INTO _hub_id, _src_db_name, _area, _mfs_root; 
    -- SELECT _i, _src_db_name, @_node;
    -- IF _token IS NOT NULL THEN
    --   SELECT _token INTO _uid;
    -- END IF;

    IF _src_db_name IS NOT NULL THEN 
      SET @s = CONCAT(
        "SELECT " ,_src_db_name,".user_permission (?, ?) INTO @resperm");
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _uid, _rid;
      DEALLOCATE PREPARE stmt; 

      SET @s = CONCAT(
        "SELECT " ,_src_db_name,".user_expiry (?, ?) INTO @resexpiry");
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _uid, _rid;
      DEALLOCATE PREPARE stmt;
      SELECT IF(_area='public', GREATEST(3, @resperm), IFNULL(@resperm, 1)) INTO @resperm;

      INSERT INTO __tmp_ids SELECT 
        _rid, _hub_id, _src_db_name, @resexpiry, _permission, CAST(@resperm AS UNSIGNED); 
    END IF;

    SELECT _i + 1 INTO _i;
  END WHILE;
  
  SELECT * FROM  __tmp_ids WHERE 
    (expiry = 0 OR expiry > UNIX_TIMESTAMP());

END $

DELIMITER ;

