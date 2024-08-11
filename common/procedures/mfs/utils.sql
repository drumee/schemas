DELIMITER $





-- =========================================================
-- Get user's share box home (top) directory
-- =========================================================
-- SHALL BE DECPRECATED 
DROP PROCEDURE IF EXISTS `mfs_sharebox_home`$
-- CREATE PROCEDURE `mfs_sharebox_home`(
--   IN _uid VARCHAR(16)
-- )
-- BEGIN
--   DECLARE _sbx_db_name VARCHAR(255);
--   DECLARE _sbx_id VARCHAR(16);

--     SELECT e.id  FROM yp.entity e INNER JOIN yp.hub h ON e.id = h.id  
--     WHERE   e.area = 'restricted' AND e.type='hub' AND h.owner_id = _uid INTO _sbx_id ;

--   -- SELECT e.id FROM yp.entity e 
--   --   INNER JOIN hub sb ON e.id=sb.owner_id 
--   --   WHERE e.owner_id=_uid AND area='restricted' INTO _sbx_id ;

--     SELECT db_name FROM yp.entity WHERE id=_sbx_id INTO _sbx_db_name;
--     SET @st = CONCAT('CALL ', _sbx_db_name ,'.mfs_home()');
--     PREPARE stamt FROM @st;
--     EXECUTE stamt;
--     DEALLOCATE PREPARE stamt;
-- END $



-- ================================================
-- get_filename
-- Returns filename of media identified by node_id
-- ================================================

DROP PROCEDURE IF EXISTS `get_filename`$
-- CREATE PROCEDURE `get_filename`(
--   IN _node_id VARCHAR(16)
-- )
-- BEGIN

--   SELECT TRIM(TRAILING '/' FROM file_path) as fname FROM media WHERE id=_node_id;

-- END $


-- =========================================================================
-- count_files
-- =========================================================================

DROP PROCEDURE IF EXISTS `count_files`$
-- CREATE PROCEDURE `count_files`(
-- )
-- BEGIN

--   SELECT COUNT(*) AS count FROM media WHERE media.category!='folder';

-- END $

-- =========================================================================
-- count_download
-- =========================================================================

DROP PROCEDURE IF EXISTS `count_download`$
-- CREATE PROCEDURE `count_download`(
--   IN _id VARCHAR(16)
-- )
-- BEGIN

--   UPDATE media SET download_count=download_count+1 WHERE id=_id;
--   SELECT * from media where id=_id;
-- END $


DELIMITER ;