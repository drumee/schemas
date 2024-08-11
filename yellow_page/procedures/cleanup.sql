DELIMITER $



DROP PROCEDURE IF EXISTS `cleanup_share_node`$
-- CREATE PROCEDURE `cleanup_share_node`()
-- BEGIN

--     DECLARE _src_sbx_sys_id INT(11) UNSIGNED; 
--     DECLARE _des_sbx_sys_id INT(11) UNSIGNED; 
--     DECLARE _notify_sys_id INT(11) UNSIGNED; 

--     DECLARE _src_sb_db        VARCHAR(50);
--     DECLARE _des_sb_db        VARCHAR(50);
--     DECLARE _src_host_id      VARCHAR(16); 
--     DECLARE _des_host_id      VARCHAR(16); 

--     DECLARE _src_owner_id     VARCHAR(16); 
--     DECLARE _des_owner_id     VARCHAR(16); 

--     DECLARE _expiry_node_id     VARCHAR(16); 


--     SELECT MIN(sys_id) FROM share_box INTO _src_sbx_sys_id; 

--     WHILE _src_sbx_sys_id IS NOT NULL DO
        
--         SELECT s.id,s.owner_id, e.db_name   
--         FROM share_box s
--         INNER JOIN entity e ON e.id = s.id
--         WHERE s.sys_id = _src_sbx_sys_id INTO _src_host_id,_src_owner_id,_src_sb_db;  
        
--        -- 1.REMOVE ORPHAN NOTIFICATION FROM THE OWNER POINT   

--         SET @sql = CONCAT(" 
--             DELETE FROM yp.notification WHERE 
--             owner_id = ",quote( _src_owner_id)," 
--             AND resource_id NOT IN (SELECT id FROM ", _src_sb_db,".media )
--         ");
                                
--         PREPARE stmt FROM @sql;
--         EXECUTE stmt;
--         DEALLOCATE PREPARE stmt;  
        
--         -- 2.REMOVE ORPHAN NOTIFICATION FROM THE USER POINT   

--         SET @sql = CONCAT(" 
--             DELETE FROM yp.notification WHERE 
--             entity_id = ",quote( _src_owner_id)," 
--             AND status = 'receive'
--             AND resource_id NOT IN (SELECT id FROM ", _src_sb_db,".media )
--         ");
                                
--         PREPARE stmt FROM @sql;
--         EXECUTE stmt;
--         DEALLOCATE PREPARE stmt; 

--         -- 3. REMOVE ORPHAN PERMISSION IN SHARE BOX DB -- NODE NOT IN MEDIA
        
--         SET @sql = CONCAT(" 
--                     DELETE FROM ",  _src_sb_db  ,".permission WHERE 
--                     resource_id NOT IN (SELECT id FROM ", _src_sb_db,".media )
--                     AND resource_id <> '*'    
--                     ");
                                
--         PREPARE stmt FROM @sql;
--         EXECUTE stmt;
--         DEALLOCATE PREPARE stmt;

--         -- 4. REMOVE ORPHAN PERMISSION IN SHARE BOX DB -- NODE NOT IN NOTIFICATION

--         SET @sql = CONCAT(" 
--                     DELETE FROM ",  _src_sb_db  ,".permission WHERE 
--                     resource_id NOT IN (SELECT resource_id FROM yp.notification )
--                     AND resource_id <> '*'    
--                     ");
                                
--         PREPARE stmt FROM @sql;
--         EXECUTE stmt;
--         DEALLOCATE PREPARE stmt;

--         -- 5. REMOVE ORPHAN SHARE IN SHARE BOX DB 
        
--         IF _src_host_id <> _src_owner_id THEN
--             SET @sql = CONCAT(" 
--                         DELETE FROM ",  _src_sb_db  ,".share WHERE 
--                         permission_id NOT IN (SELECT sys_id FROM ", _src_sb_db,".permission )
--                         ");
                                    
--             PREPARE stmt FROM @sql;
--             EXECUTE stmt;
--             DEALLOCATE PREPARE stmt; 
--         END IF;

        
--         SELECT MIN(sys_id) FROM share_box INTO _des_sbx_sys_id; 
        
        
--         WHILE _des_sbx_sys_id IS NOT NULL DO

            
--             SELECT s.id,s.owner_id, e.db_name   
--             FROM share_box s
--             INNER JOIN entity e ON e.id = s.id
--             WHERE s.sys_id = _des_sbx_sys_id INTO _des_host_id,_des_owner_id,_des_sb_db;   
            

--             IF _des_sb_db <> _src_sb_db THEN

--             -- 6.REMOVE ORPHAN NODE FROM THE DESTINATION SHARE BOX  
--                 -- Logic :  
--                 -- pick the node from media based on host id in the detination db and delete the node which are not avaialbe in the 
--                 -- host's media table    

--                 SET @sql = CONCAT(" 
--                     DELETE  FROM ",_des_sb_db, ".media WHERE host_id =",quote( _src_host_id)," 
--                     AND id <> ",quote( _src_host_id)," 
--                     AND id NOT IN (SELECT id FROM ", _src_sb_db,".media )
--                 ");
                                
--                 PREPARE stmt FROM @sql;
--                 EXECUTE stmt;
--                 DEALLOCATE PREPARE stmt;    
            
--             -- 7. DELETE THE EXPIRED NODES
--                SELECT MIN(sys_id) FROM yp.notification WHERE  (expiry_time <= UNIX_TIMESTAMP() AND expiry_time > 0) AND 
--                    owner_id = _src_owner_id  AND  entity_id = _des_owner_id INTO _notify_sys_id;

--                 WHILE _notify_sys_id IS NOT NULL DO

--                     SELECT resource_id FROM yp.notification WHERE sys_id = _notify_sys_id INTO _expiry_node_id;
                    
--                     SELECT _notify_sys_id ,_src_owner_id,_des_owner_id,_expiry_node_id ;
                                       
                    
--                     SET @sql = CONCAT("CALL ",_src_sb_db, ".sbx_remove (", QUOTE(_src_owner_id),",",QUOTE(_expiry_node_id), ",",QUOTE(_des_owner_id),")");
--                     PREPARE stmtx FROM @sql;
--                     EXECUTE stmtx;
--                     DEALLOCATE PREPARE stmtx; 
                   
--                     SET @sql = CONCAT("CALL ",_src_sb_db, ".permission_revoke (",QUOTE(_expiry_node_id), ",",QUOTE(_des_owner_id),")");
--                     PREPARE stmtx FROM @sql;
--                     EXECUTE stmtx;
--                     DEALLOCATE PREPARE stmtx; 

--                     CALL yp.yp_notification_remove (_expiry_node_id, _des_owner_id ) ;
                   
--                     SELECT MIN(sys_id) FROM yp.notification WHERE (expiry_time <= UNIX_TIMESTAMP() AND expiry_time > 0)  AND
--                     owner_id = _src_owner_id  AND  entity_id = _des_owner_id  AND  sys_id > _notify_sys_id INTO _notify_sys_id;   
                
--                 END WHILE;    

--             END IF;
                
--             SELECT MIN(sys_id) FROM share_box WHERE sys_id > _des_sbx_sys_id INTO _des_sbx_sys_id; 
--         END WHILE;

--         SELECT MIN(sys_id) FROM share_box WHERE sys_id > _src_sbx_sys_id INTO _src_sbx_sys_id; 
--     END WHILE;

-- END $
DELIMITER ;








