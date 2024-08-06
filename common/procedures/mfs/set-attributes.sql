DELIMITER $

-- ===============================================================
-- 
-- ===============================================================
DROP PROCEDURE IF EXISTS `mfs_set_attributes`$
-- CREATE PROCEDURE `mfs_set_attributes`(
--   IN _column    VARCHAR(200),
--   IN _value     VARCHAR(2000),
--   IN _id        VARCHAR(16)
-- )
-- BEGIN
--   SET @s = CONCAT("UPDATE media SET `", _column, "`='", _value, "' WHERE id='", _id, "'");
--   PREPARE stmt FROM @s;
--   EXECUTE stmt;
--   DEALLOCATE PREPARE stmt;
--   CALL mfs_node_attr(_id);
-- END $

-- ===============================================================
-- 
-- ===============================================================
DROP PROCEDURE IF EXISTS `mfs_set_attributes_next`$
-- CREATE PROCEDURE `mfs_set_attributes_next`(
--   IN _column    VARCHAR(200),
--   IN _value     VARCHAR(2000),
--   IN _id        VARCHAR(16),
--   IN _show      BOOLEAN
-- )
-- BEGIN
--   SET @s = CONCAT("UPDATE media SET `", _column, "`='", _value, "' WHERE id='", _id, "'");
--   PREPARE stmt FROM @s;
--   EXECUTE stmt;
--   DEALLOCATE PREPARE stmt;
--   IF _show THEN 
--     CALL mfs_node_attr(_id);
--   END IF;
-- END $

-- ===============================================================
-- 
-- SHALL REPLACE mfs_set_attributes for harmonizing API (id first)
-- 
-- ===============================================================
-- DROP PROCEDURE IF EXISTS `mfs_set_attr`$
-- CREATE PROCEDURE `mfs_set_attr`(
--   IN _id        VARCHAR(16),
--   IN _column    VARCHAR(200),
--   IN _value     JSON
-- )
-- BEGIN
--   IF _column='metadata' THEN
--     IF NOT JSON_VALID(_value) THEN
--       SELECT '{}' INTO _value;
--     END IF;
--     IF JSON_VALID(_value) THEN 
--       UPDATE media SET metadata=_value where id=_id;
--     END IF;
--   ELSE 
--     SET @s = CONCAT("UPDATE media SET `", _column, "`='", _value, "' WHERE id='", _id, "'");
--     PREPARE stmt FROM @s;
--     EXECUTE stmt;
--     DEALLOCATE PREPARE stmt;
--   END IF;
--   CALL mfs_node_attr(_id);
-- END $


DROP PROCEDURE IF EXISTS `mfs_set_attr_next`$
-- CREATE PROCEDURE `mfs_set_attr_next`(
--   IN _id        VARCHAR(16),
--   IN _column    VARCHAR(200),
--   IN _value     JSON,
--   IN _show      BOOLEAN
-- )
-- BEGIN
--   IF _column='metadata' THEN
--     IF NOT JSON_VALID(_value) THEN
--       SELECT '{}' INTO _value;
--     END IF;
--     IF JSON_VALID(_value) THEN 
--       UPDATE media SET metadata=_value where id=_id;
--     END IF;
--   ELSE 
--     SET @s = CONCAT("UPDATE media SET `", _column, "`='", _value, "' WHERE id='", _id, "'");
--     PREPARE stmt FROM @s;
--     EXECUTE stmt;
--     DEALLOCATE PREPARE stmt;
--   END IF;
--   IF _show THEN 
--     CALL mfs_node_attr(_id);
--   END IF;  
-- END $


DELIMITER ;