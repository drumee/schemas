
DELIMITER $

DROP PROCEDURE IF EXISTS `team_hub_create`$
DROP PROCEDURE IF EXISTS `team_create_hub`$
-- CREATE PROCEDURE `team_create_hub`(
--   IN _specs  VARCHAR(150),
--   IN _domain VARCHAR(150),
--   IN _oid VARCHAR(16)
-- )
-- BEGIN

--   DECLARE _room_hub_id VARCHAR(16);
--   DECLARE _room_hub_db VARCHAR(50);
--   DECLARE _room_hub_ident VARCHAR(80); 
--   DECLARE _room_hub_fqdn VARCHAR(1024);

--   SELECT id, db_name ,ident FROM yp.entity WHERE type='hub' AND area='pool' LIMIT 1 
--   INTO _room_hub_id, _room_hub_db, _room_hub_ident;

--   SELECT CONCAT(_room_hub_ident, '.', _domain) INTO _room_hub_fqdn;

--   UPDATE yp.entity SET area='private', status='active'  WHERE id=_room_hub_id;
--   INSERT INTO yp.vhost VALUES (null, _room_hub_fqdn, _room_hub_id, _domain);

--   INSERT INTO yp.hub (id, owner_id, origin_id,  name,  keywords, dmail, profile)
--   VALUES ( _room_hub_id, _oid, _oid,  _specs, 'Key words', yp.get_dmail(_room_hub_ident), '{}');

--   CALL join_hub(_room_hub_id);

--   SELECT _room_hub_id id, _room_hub_db db_name;
  

-- END $

-- CALL team_hub_create('spec12','drumee.com','46fb4fc946fb4fce');

DROP PROCEDURE IF EXISTS `team_folder_create`$
DROP PROCEDURE IF EXISTS `team_create_owner_folder`$
-- CREATE PROCEDURE `team_create_owner_folder`(
--   IN _name VARCHAR(100),
--   IN _oid VARCHAR(16),
--   IN _team_hub_id VARCHAR(16)
-- )
-- BEGIN

--   DECLARE _home_id VARCHAR(16);
--   DECLARE _temp_nid VARCHAR(16);
   
--     -- owner folder 
    
--   SELECT id FROM media WHERE parent_id='0' INTO _home_id; 
--   CREATE TEMPORARY TABLE IF NOT EXISTS  __register_stack LIKE template.__register_stack;
--   DELETE FROM __register_stack;
--   CALL mfs_new_node(
--     _oid,
--     _oid,
--     _name,
--     _home_id,
--     'folder',
--     '',
--     'folder',
--     NULL,
--     NULL,
--   0);
--   SELECT id FROM __register_stack INTO _temp_nid;
--   UPDATE media SET parent_id= _temp_nid WHERE id = _team_hub_id; 
  
--   SELECT * FROM media WHERE id = _temp_nid; 

-- END $



DROP PROCEDURE IF EXISTS `team_member_folder_create`$
DROP PROCEDURE IF EXISTS `team_create_member_folder`$
-- CREATE PROCEDURE `team_create_member_folder`(
--   IN _mids JSON,  
--   IN _oid VARCHAR(16),
--   IN _team_hub_id VARCHAR(16)
-- )
-- BEGIN
--   DECLARE _idx INT(4) DEFAULT 0; 
--   DECLARE _mid VARCHAR(16);
--   DECLARE _temp_parent_id VARCHAR(16);
--   DECLARE _temp_user_filename VARCHAR(1024);
--   DECLARE _team_hub_db VARCHAR(50);
--   DECLARE _fullname VARCHAR(255) ; 


--   DROP TABLE IF EXISTS _final_team; 
--   CREATE TEMPORARY TABLE _final_team (
--     nid varchar(16) DEFAULT NULL , 
--     uid varchar(16) DEFAULT NULL
--   );

--   SELECT db_name FROM yp.entity WHERE id=_team_hub_id INTO _team_hub_db;


--   SET @st = CONCAT( "SELECT id FROM ",_team_hub_db,".media WHERE parent_id='0' INTO  @home_id");
--   PREPARE stmt3 FROM @st;
--   EXECUTE stmt3;
--   DEALLOCATE PREPARE stmt3;  
  
    
--   WHILE _idx < JSON_LENGTH(_mids) DO 
--     SELECT get_json_array(_mids, _idx) INTO _mid;
--     SELECT CONCAT(firstname, " ", lastname) FROM contact WHERE id  = _mid INTO _fullname ;
  
--     SELECT 
--     CONCAT(get_json_object(d.profile, 'firstname'), ' ', get_json_object(d.profile, 'lastname'))  
--     FROM yp.drumate d WHERE  d.id= _mid AND _fullname IS NULL INTO _fullname; 

--       -- Ensure the  table __register_stack existence
--     SET @st = CONCAT( "CREATE TEMPORARY TABLE IF NOT EXISTS  ",_team_hub_db,".__register_stack LIKE template.__register_stack"); 
--     PREPARE stmt FROM @st;
--     EXECUTE stmt;
--     DEALLOCATE PREPARE stmt;


--     SET @st = CONCAT( "DELETE FROM ",_team_hub_db,".__register_stack"); 
--     PREPARE stmt1 FROM @st;
--     EXECUTE stmt1;
--     DEALLOCATE PREPARE stmt1;

--     SET @st = CONCAT("CALL ", _team_hub_db ,".mfs_register(",
--       QUOTE(_oid),",",
--       QUOTE(_fullname),",",
--       QUOTE(@home_id), ",'folder','','folder',NULL,NULL,0)" 
--     );
--     PREPARE stmt2 FROM @st;
--     EXECUTE stmt2;
--     DEALLOCATE PREPARE stmt2;

--     SET @st = CONCAT("CALL ", _team_hub_db, ".mfs_new_node(?,?,?,?,?,?,?,?,?,?)");
--     PREPARE stmt2 FROM @st;
--     EXECUTE stmt2 USING 
--       _oid,
--       _oid,
--       _fullname,
--       @home_id,
--       'folder',
--       '',
--       'folder',
--       NULL,
--       NULL, 
--       0;           
--     DEALLOCATE PREPARE stmt2;

 

--     SET @st = CONCAT( "SELECT id FROM ",_team_hub_db,".__register_stack INTO @temp_nid");
--     PREPARE stamt FROM @st;
--     EXECUTE stamt;
--     DEALLOCATE PREPARE stamt; 
--     INSERT INTO _final_team SELECT @temp_nid, _mid;

--     SET @st = CONCAT(
--       "UPDATE ",_team_hub_db,".media SET metadata=",
--       QUOTE(JSON_OBJECT('uid', _mid, 'access', 'personal', 'fullname', _fullname)),
--     " WHERE id=", QUOTE(@temp_nid));
--     PREPARE stamt FROM @st;
--     EXECUTE stamt;
--     DEALLOCATE PREPARE stamt; 
    
--     SELECT _idx + 1 INTO _idx; 
--   END WHILE;

--   SELECT * from _final_team;


-- END $

DELIMITER ;
