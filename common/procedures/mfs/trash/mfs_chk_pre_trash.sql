DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_chk_pre_trash`$
CREATE PROCEDURE `mfs_chk_pre_trash`(
  IN _nodes JSON,
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _modify_perm TINYINT(4)
)
BEGIN

  DECLARE _idx INT DEFAULT 0; 
  DECLARE _nid VARCHAR(16);
  DECLARE _shub_id VARCHAR(16);
  DECLARE _shub_db VARCHAR(40);

 
  DROP TABLE IF EXISTS `_mytree`; 
  CREATE  TEMPORARY TABLE `_mytree` (
          id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
          parent_id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
          category varchar(16) DEFAULT NULL
          );


  WHILE _idx < JSON_LENGTH(_nodes) DO 

        SELECT JSON_UNQUOTE(JSON_EXTRACT(_nodes, CONCAT("$[", _idx, "]"))) INTO @_node;
        SELECT JSON_VALUE(@_node, "$.nid") INTO _nid;
        SELECT JSON_VALUE(@_node, "$.hub_id") INTO _shub_id;
        SELECT db_name FROM yp.entity WHERE id = _shub_id INTO _shub_db; 
   

       --  DELETE FROM _mytree;
        SET @st = CONCAT
        ( " 
           INSERT INTO _mytree
           WITH RECURSIVE mytree AS (
            SELECT id, parent_id ,category
            FROM ",_shub_db,".media WHERE id =", QUOTE(_nid),"
            UNION ALL
            SELECT m.id, m.parent_id ,m.category
            FROM ",_shub_db,".media AS m JOIN mytree AS t ON m.parent_id = t.id  
          )
         SELECT id, parent_id ,category FROM mytree;");
        PREPARE stmt FROM @st;
        EXECUTE stmt ;
        DEALLOCATE PREPARE stmt; 

      SELECT _idx + 1 INTO _idx;
  END WHILE; 
    SELECT 1 is_hub FROM  _mytree WHERE category = 'hub' limit 1;
END$


DELIMITER ;


