
DELIMITER $

  
-- =======================================================================
--
-- =======================================================================
DROP PROCEDURE IF EXISTS `acl_array_check_next`$
CREATE PROCEDURE `acl_array_check_next`(
  IN _key VARCHAR(16),
  IN _permission TINYINT(4),
  IN _nodes JSON
)
BEGIN

  DECLARE _uid VARCHAR(16);
  DECLARE _owner_id VARCHAR(16);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _area VARCHAR(16);
  DECLARE _src_db_name VARCHAR(255);
  DECLARE _mfs_root VARCHAR(512);

  DECLARE _rid VARCHAR(16);
  DECLARE _i INT(8) DEFAULT 0;
  DECLARE _j INT(8) DEFAULT 0;

  SELECT id FROM yp.entity WHERE id=_key INTO _uid;

  DROP TABLE IF EXISTS __tmp_ids;
  CREATE TEMPORARY TABLE __tmp_ids(
    `id` varchar(16) DEFAULT NULL,
    `hub_id` varchar(16) DEFAULT NULL,
    db_name varchar(90) DEFAULT NULL,
    expiry tinyint(4) unsigned,
    asked  tinyint(4) unsigned DEFAULT 1,
    privilege int(11) 
  ); 

  IF _permission IS NULL OR _permission=0 THEN 
    SET _permission = 1;
  END IF;

  WHILE _i < JSON_LENGTH(_nodes) DO 
    -- SELECT JSON_UNQUOTE(JSON_EXTRACT(_nodes, CONCAT("$[", _i, "]"))) INTO @_node;
    SELECT get_json_array(_nodes, _i) INTO @_node;
    -- SELECT JSON_UNQUOTE(JSON_EXTRACT(@_node, "$.nid")) INTO @_nids;
    SELECT get_json_object(@_node, "nid") INTO @_nids;

    SELECT 0 INTO  _j;
    WHILE _j < JSON_LENGTH(@_nids) DO 
      -- SELECT JSON_UNQUOTE(JSON_EXTRACT(@_nids,CONCAT("$[", _j, "]"))) INTO _rid;
      SELECT get_json_array(@_nids, _j) INTO _rid;
      SELECT id, db_name, area, owner_id, concat(home_dir, "__storage__/")
        FROM yp.entity LEFT JOIN yp.hub USING(id) WHERE 
        -- id = yp.hub_id(JSON_UNQUOTE(JSON_EXTRACT(@_node, "$.hub_id")))
        id = yp.hub_id(get_json_object(@_node, "hub_id"))
        INTO _hub_id, _src_db_name, _area, _owner_id, _mfs_root; 
      -- SELECT _src_db_name, @_node;

      IF _src_db_name IS NOT NULL THEN 
        SET @s = CONCAT(
          "SELECT " ,_src_db_name,".user_permission (", QUOTE(_uid),",",QUOTE(_rid), ") INTO @resperm");
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt; 

        SET @s = CONCAT(
          "SELECT " ,_src_db_name,".user_expiry (", QUOTE(_uid),",",QUOTE(_rid), ") INTO @resexpiry");
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        SELECT IF(_area='public', GREATEST(7, @resperm), GREATEST(1, @resperm)) INTO @resperm;
        INSERT INTO __tmp_ids SELECT 
          _rid, _hub_id, _src_db_name, @resexpiry, _permission, CAST(@resperm AS UNSIGNED); 
      END IF;          
      SELECT _j + 1 INTO _j;
    END WHILE;
    SELECT _i + 1 INTO _i;
  END WHILE;
  
  SELECT * FROM  __tmp_ids WHERE 
    (expiry = 0 OR expiry > UNIX_TIMESTAMP());

END $


DELIMITER ;

