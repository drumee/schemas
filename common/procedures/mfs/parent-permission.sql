DELIMITER $

-- DROP FUNCTION IF EXISTS `parent_permission`$
-- CREATE FUNCTION `parent_permission`(
--   _uid VARCHAR(16) CHARACTER SET ascii,
--   _node_id VARCHAR(16) CHARACTER SET ascii
-- )
-- RETURNS TINYINT(2) DETERMINISTIC
-- BEGIN
--   DECLARE _perm TINYINT(4) DEFAULT 0;

--     WITH RECURSIVE parent_media AS 
--       (
--         SELECT * FROM (SELECT m.id,m.parent_id ,IFNULL(p.permission,0) permission 
--         FROM media m 
--         LEFT JOIN permission p ON 
--           p.resource_id=m.parent_id AND p.entity_id IN(_uid, '*') -- AND p.assign_via != 'no_traversal'
--         WHERE m.id = _node_id  LIMIT 1) a
--           UNION ALL
--         SELECT  m.id, m.parent_id,IFNULL(p.permission,0) permission 
--         FROM media m
--         LEFT JOIN permission p ON 
--           p.resource_id=m.parent_id AND  p.entity_id IN(_uid, '*') AND p.assign_via != 'no_traversal'
--         INNER JOIN parent_media AS t ON 
--           m.id = t.parent_id  AND m.parent_id <> '0'  AND t.permission = 0
--       )
--       SELECT permission FROM parent_media WHERE permission <> 0  INTO  _perm ;

--       RETURN _perm;
-- END $


-- DROP FUNCTION IF EXISTS `parent_permission_old`$
-- CREATE FUNCTION `parent_permission_old`(
--   _uid VARCHAR(16),
--   _node_id VARCHAR(16)
-- )
-- RETURNS TINYINT(2) DETERMINISTIC
-- BEGIN

--   DECLARE _pid VARCHAR(16);
--   DECLARE _perm TINYINT(4) DEFAULT 0;
--   DECLARE _res VARCHAR(16);
--   DECLARE _depth SMALLINT DEFAULT 0;
--   SELECT m.parent_id, IFNULL(p.permission,0) FROM media m LEFT JOIN permission p ON 
--     p.resource_id=m.parent_id AND  p.entity_id IN(_uid, '*') WHERE m.id=_node_id  LIMIT 1
--     INTO _pid, _perm;
--   WHILE _depth  < 120 AND (_pid != '0' OR _pid IS NULL) AND _perm = 0 DO
--     SELECT m.parent_id, IFNULL(p.permission,0) FROM media m LEFT JOIN permission p ON 
--       p.resource_id=m.parent_id AND  p.entity_id IN(_uid, '*') AND p.assign_via != 'no_traversal'  WHERE  m.id=_pid 
--       LIMIT 1
--       INTO _pid, _perm;
--       SELECT _depth + 1 INTO _depth;
--   END WHILE;
--   RETURN _perm;

-- END $



DROP FUNCTION IF EXISTS `parent_permission`$
CREATE FUNCTION `parent_permission`(
  _uid VARCHAR(16) CHARACTER SET ascii,
  _node_id VARCHAR(16) CHARACTER SET ascii
)
RETURNS TINYINT(2) DETERMINISTIC
BEGIN
  DECLARE _perm TINYINT(4) DEFAULT 0;

    WITH RECURSIVE parent_media AS 
      (
        SELECT m.id,m.parent_id ,CASE WHEN p.assign_via = 'root' THEN 0  ELSE IFNULL(p.permission,0) END permission , p.assign_via
        FROM media m 
        LEFT JOIN permission p ON 
          p.resource_id=m.parent_id AND p.entity_id IN(_uid, '*') 
        WHERE m.id = _node_id  
          UNION ALL
        SELECT  m.id, m.parent_id,CASE WHEN p.assign_via = 'root' THEN 0  ELSE IFNULL(p.permission,0) END permission, p.assign_via
        FROM media m
        LEFT JOIN permission p ON 
          p.resource_id=m.parent_id AND  p.entity_id IN(_uid, '*') 
        INNER JOIN parent_media AS t ON 
          m.id = t.parent_id  AND m.parent_id <> '0'  AND t.permission = 0 
          AND IFNULL(t.assign_via,0) NOT IN ('no_traversal','root')
      )
      SELECT max(permission) FROM parent_media WHERE permission <> 0  INTO  _perm ;

      RETURN IFNULL(_perm,0);
END $



DELIMITER ;

