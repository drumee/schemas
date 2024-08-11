DEPRECATED !!!

DELIMITER $

-- DROP PROCEDURE IF EXISTS `desk_env`$
-- CREATE PROCEDURE `desk_env`(
-- )
-- BEGIN
--   DECLARE _vhost VARCHAR(255);
--   DECLARE _holder_id VARCHAR(16);
--   DECLARE _area VARCHAR(50);
--   DECLARE _home_dir VARCHAR(512);
--   DECLARE _home_id VARCHAR(16);
--   DECLARE _db_name VARCHAR(512);
--   DECLARE _accessibility VARCHAR(16);

--   CALL mediaEnv(_vhost, _holder_id, _area, _home_dir, _home_id, _db_name, _accessibility);
--   SELECT 
--     _home_id AS home_id,
--     _home_id AS nid,
--     _holder_id AS holder_id, 
--     _holder_id AS oid,
--     _vhost AS vhost, 
--     _area AS area;
-- END $


-- ==============================================================
-- desk_home
-- List files + directories under directory identified by node_id
-- owner_id is the id of the hub on which media are stored
-- host_id is the same when media is not a link ( which may be a pointer to another hub)
-- host_id is the id of the hub that actually host the media 
-- ==============================================================


-- DROP PROCEDURE IF EXISTS `desk_home`$ 
-- CREATE PROCEDURE `desk_home`(
--   IN _page TINYINT(4)      /* DEPRECATED ???? ------------ */
-- )
-- BEGIN

--   DECLARE _range bigint;
--   DECLARE _offset bigint;
--   DECLARE _vhost VARCHAR(255);
--   DECLARE _holder_id VARCHAR(16);
--   DECLARE _area VARCHAR(50);
--   DECLARE _home_dir VARCHAR(512);
--   DECLARE _home_id VARCHAR(16);
--   DECLARE _db_name VARCHAR(512);
--   DECLARE _accessibility VARCHAR(16);

--   CALL pageToLimits(_page, _offset, _range);
--   CALL mediaEnv(_vhost, _holder_id, _area, _home_dir, _home_id, _db_name, _accessibility);

--   SELECT
--     media.id  AS nid,
--     parent_id AS pid,
--     parent_id AS parent_id,
--     _holder_id AS holder_id,
--     _home_id AS home_id,
--     IF(media.category='hub', 
--       (SELECT id FROM yp.entity WHERE entity.id=media.id), _holder_id
--     ) AS oid,    
-- --    media.owner_id AS oid,
--     caption,
--     capability,
--     IF(media.category='hub', (
--       SELECT accessibility FROM yp.entity WHERE entity.id=media.id), _accessibility
--     ) AS accessibility,
--     IF(media.category='hub', (
--       SELECT status FROM yp.entity WHERE entity.id=media.id), status
--     ) AS status,
--     media.extension AS ext,
--     media.category AS ftype,
--     media.category AS filetype,
--     media.mimetype,
--     download_count AS view_count,
--     geometry,
--     upload_time AS ctime,
--     publish_time AS ptime,
--     parent_path,
--     IF(parent_path='' or parent_path is NULL , '/', parent_path) AS user_path,
--     IF(media.category='hub', (
--       SELECT `name` FROM yp.hub WHERE hub.id=media.id), user_filename
--     ) AS filename,
--     IF(media.category='hub', (
--       SELECT space FROM yp.entity WHERE entity.id=media.id), filesize
--     ) AS filesize,
--     firstname,
--     lastname,
--     remit,
--     IF(media.category='hub', (
--       SELECT vhost FROM yp.entity WHERE entity.id=media.id), _vhost
--     ) AS vhost,    
--     -- IF(media.category='hub', (
--     --   SELECT id FROM yp.entity WHERE entity.id=media.id), _holder_id
--     -- ) AS host_id,    
--     _page as page,
--     IF(media.category='hub', (
--       SELECT area FROM yp.entity WHERE entity.id=media.id), _area
--     ) AS area,
--     rank,
--     'desk' AS context
--   FROM  media LEFT JOIN (yp.filecap, yp.drumate) ON 
--   media.extension=filecap.extension AND origin_id=yp.drumate.id 
--   WHERE parent_id=_home_id AND status='active'
--   ORDER BY rank ASC, ctime DESC LIMIT _offset, _range;
-- END $


-- =========================================================
-- desk_create_hub
-- hubs are actually pre created by the hubs factory
-- =========================================================

-- DROP PROCEDURE IF EXISTS `desk_create_hub_next`$
-- CREATE PROCEDURE `desk_create_hub_next`(
-- DROP PROCEDURE IF EXISTS `desk_create_hub`$
-- CREATE PROCEDURE `desk_create_hub`(
--   IN _ident VARCHAR(80),
--   IN _area VARCHAR(16),
--   IN _oid  VARCHAR(16),
--   IN _profile JSON
-- )
-- BEGIN
--   DECLARE _hub_id VARCHAR(16);
--   DECLARE _hub_db VARCHAR(50);
--   DECLARE _default_privilege TINYINT(4);
--   DECLARE _dmail VARCHAR(500);
--   DECLARE _domain VARCHAR(500);
--   DECLARE _folders JSON;
--   DECLARE _fqdn VARCHAR(1024);  /* Fully Qualified Domain Name*/
--   DECLARE _rollback BOOL DEFAULT 0;   
--   DECLARE  _domain_id INT;
--   DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET _rollback = 1;  
--   -- get domain name
--   SELECT IFNULL(
--     get_json_object(_profile, "domain"), yp.get_domain_name(database())
--   ) INTO _domain;
   
--   SELECT IF(count(*), id, 1) FROM yp.domain WHERE `name`=_domain INTO _domain_id;
--   SELECT get_json_object(_profile, "folders") INTO _folders;

--   SELECT JSON_REMOVE(_profile, "$.domain") INTO _profile;
--   SELECT JSON_REMOVE(_profile, "$.folders") INTO _profile;
--   START TRANSACTION;
--   -- pick one prebuilt by hubs factory
--   SELECT id, db_name  FROM yp.entity WHERE type='hub' AND area='pool' 
--     LIMIT 1 INTO _hub_id, _hub_db;

--   SELECT CONCAT(_ident, '.', _domain) INTO _fqdn;

--   UPDATE yp.entity SET area=_area, ident=_ident, status='active', dom_id =_domain_id, vhost=_fqdn WHERE id=_hub_id;
--   SELECT CASE _area
--     WHEN 'public' THEN 3
--     WHEN 'private' THEN 7 
--     WHEN 'stricted' THEN 3
--     ELSE 0 
--   END INTO _default_privilege;

--   UPDATE yp.entity SET settings=json_set(settings, "$.default_privilege", _default_privilege) 
--     WHERE id=_hub_id;

--   INSERT INTO yp.vhost VALUES (null, _fqdn, _hub_id, _domain_id);
--   INSERT INTO yp.hub (
--     `id`, `owner_id`, `origin_id`, 
--     `name`, 
--     `keywords`, `dmail`, `profile`)
--   VALUES (
--     _hub_id, _oid, _oid, 
--     IFNULL(get_json_object(_profile, "name"), _fqdn),
--     "Key words", yp.get_dmail(_ident), _profile);

--   CALL join_hub(_hub_id);
--   CALL permission_grant(_hub_id, _oid, 0, 63, 'system', '');
--   SET @s = CONCAT("CALL `", _hub_db, "`.permission_grant('*',?, 0, 63, 'system', '')");
--   PREPARE stmt FROM @s;
--   EXECUTE stmt USING _oid;
--   DEALLOCATE PREPARE stmt;

--   IF _area = "public" THEN 
--     SET @s = CONCAT("CALL `", 
--       _hub_db, 
--       "`.permission_grant('*', '*', 0, 3, 'system', '')"
--     );
--     PREPARE stmt FROM @s;
--     EXECUTE stmt;
--     DEALLOCATE PREPARE stmt;
--   END IF;
  
--   IF _folders IS NOT NULL THEN 
--     SET @s = CONCAT("CALL `", _hub_db,"`.mfs_init_folders(", quote(_folders), ",", true, ");");
--     PREPARE stmt FROM @s;
--     EXECUTE stmt;
--     DEALLOCATE PREPARE stmt;
--   END IF;

--   SET @s = CONCAT("CALL `", _hub_db,"`.mfs_hub_chat_init();");
--   PREPARE stmt FROM @s;
--   EXECUTE stmt;
--   DEALLOCATE PREPARE stmt;

--   SET @s = CONCAT("CALL `", _hub_db,"`.mfs_trash_init();");
--   PREPARE stmt FROM @s;
--   EXECUTE stmt;
--   DEALLOCATE PREPARE stmt;


--   SELECT *, 0 as failed,  _default_privilege default_privilege FROM yp.entity WHERE ident=_ident;

--   IF _rollback THEN
--     ROLLBACK;
--     SELECT 1 as failed;
--   ELSE
--     COMMIT;
--   END IF;
-- END$


DELIMITER ;
