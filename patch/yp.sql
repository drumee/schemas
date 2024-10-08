-- DELIMITER $
-- DROP PROCEDURE IF EXISTS `patch_areas`$
-- CREATE PROCEDURE `patch_areas`(
-- )
-- BEGIN
--   DECLARE _id VARBINARY(16);
--   DECLARE _db_name VARCHAR(80);
--   DECLARE _more_rows BOOLEAN DEFAULT TRUE;
--   DECLARE _list CURSOR FOR
--     select id, db_name from entity where type='drumate';
--   DECLARE CONTINUE HANDLER FOR NOT FOUND SET _more_rows = FALSE;
--   OPEN _list;
--
--   cloop: LOOP
--     FETCH _list INTO _id, _db_name;
--     IF NOT _more_rows THEN
--       LEAVE cloop;
--     END IF;
--     SET @a1 = CONCAT("INSERT IGNORE INTO areas SELECT id, ", quote(_id),
--        ", 'public' FROM `", _db_name, "`.`areas` WHERE level='public'");
--     PREPARE stmt FROM @a1;
--     EXECUTE stmt;
--     DEALLOCATE PREPARE stmt;
--
--     SET @a1 = CONCAT("INSERT IGNORE INTO areas SELECT id, ", quote(_id),
--        ", 'restricted' FROM `", _db_name, "`.`areas` WHERE level='restricted'");
--     PREPARE stmt FROM @a1;
--     EXECUTE stmt;
--     DEALLOCATE PREPARE stmt;
--
--     SET @a1 = CONCAT("INSERT IGNORE INTO areas SELECT id, ", quote(_id),
--        ", 'private' FROM `", _db_name, "`.`areas` WHERE level='private'");
--     PREPARE stmt FROM @a1;
--     EXECUTE stmt;
--     DEALLOCATE PREPARE stmt;
-- --    SELECT @a1;
-- --     SET @a1 = CONCAT("SELECT id FROM `", _db_name, "`.`areas` WHERE level='public' INTO @_aid;");
-- --     SET @a2 = CONCAT("UPDATE areas SET level='public', owner_id=", quote(_id), " WHERE aid=@_aid;");
-- --     SET @b1 = CONCAT("SELECT id FROM `", _db_name, "`.`areas` WHERE level='restricted' INTO @_aid;");
-- --     SET @b2 = CONCAT("UPDATE areas SET level='restricted', owner_id=", quote(_id), " WHERE aid=@_aid;");
-- --     SET @c1 = CONCAT("SELECT id FROM `", _db_name, "`.`areas` WHERE level='private' INTO @_aid;");
-- --     SET @c2 = CONCAT("UPDATE areas SET level='private', owner_id=", quote(_id), " WHERE aid=@_aid;");
-- --
-- --     PREPARE stmt FROM @a1;
-- --     EXECUTE stmt;
-- --     DEALLOCATE PREPARE stmt;
-- --     PREPARE stmt FROM @a2;
-- --     EXECUTE stmt;
-- --     DEALLOCATE PREPARE stmt;
-- --
-- --     PREPARE stmt FROM @b1;
-- --     EXECUTE stmt;
-- --     DEALLOCATE PREPARE stmt;
-- --     PREPARE stmt FROM @b2;
-- --     EXECUTE stmt;
-- --     DEALLOCATE PREPARE stmt;
-- --
-- --     PREPARE stmt FROM @c1;
-- --     EXECUTE stmt;
-- --     DEALLOCATE PREPARE stmt;
-- --     PREPARE stmt FROM @c2;
-- --     EXECUTE stmt;
-- --     DEALLOCATE PREPARE stmt;
--
--   END LOOP cloop;
-- END $
-- DELIMITER ;
