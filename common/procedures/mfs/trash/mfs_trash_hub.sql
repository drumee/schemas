DELIMITER $




-- =========================================================
-- TRASHING A HUB NODE
-- =========================================================
DROP PROCEDURE IF EXISTS `mfs_trash_hub`$
-- CREATE PROCEDURE `mfs_trash_hub`(
--   IN _nid VARCHAR(16),
--   IN _uid VARCHAR(16),
--   OUT _output VARCHAR(1000)
-- )
-- BEGIN

--   DECLARE _owner_id VARCHAR(16);
--   DECLARE _node_hub_db VARCHAR(40);
--   DECLARE _user_hub_db VARCHAR(40);

--   -- SELECT id FROM yp.entity WHERE db_name = database() INTO _uid;
--   SELECT owner_id FROM yp.hub WHERE id = _nid INTO _owner_id;
--   SELECT `db_name` FROM yp.entity WHERE id = _nid INTO _node_hub_db;
--   SELECT `db_name` FROM yp.entity WHERE id = _uid INTO _user_hub_db;
  
--   IF _uid = _owner_id THEN
--     SET @sql = CONCAT(
--       "CALL  ", _node_hub_db, ".remove_all_members (", quote(_owner_id), ")" );
--     PREPARE hub_stmt FROM @sql;
--     EXECUTE hub_stmt;
--     DEALLOCATE PREPARE hub_stmt;

--     SET @sql = CONCAT(
--       "CALL  ", _user_hub_db, ".mfs_trash_node (", quote(_nid), ")" );
--     PREPARE hub_stmt FROM @sql;
--     EXECUTE hub_stmt;
--     DEALLOCATE PREPARE hub_stmt;
--   ELSE 
    
--     SET @sql = CONCAT(
--       "CALL  ", _user_hub_db, ".leave_hub (", quote(_nid), ")" );
--     PREPARE hub_stmt FROM @sql;
--     EXECUTE hub_stmt;
--     DEALLOCATE PREPARE hub_stmt;
    
--     SET @sql = CONCAT("CALL  " , _node_hub_db ,".hub_add_action_log (?,?,?,?,?,?)");
--     PREPARE hub_stmt FROM @sql;
--     EXECUTE hub_stmt USING _nid,'left','member','admin',null,'has been left';
--     DEALLOCATE PREPARE hub_stmt;

--     SELECT NULL  INTO @huboutput;
--     SET @sql = CONCAT(
--       " SELECT user_filename FROM ", _user_hub_db, ".media where id= ", quote(_nid), "INTO @huboutput" );
--     PREPARE hub_stmt FROM @sql;
--     EXECUTE hub_stmt;
--     DEALLOCATE PREPARE hub_stmt;
    

--     SELECT @huboutput  INTO _output;
--   END IF;
-- END $

DELIMITER ;
