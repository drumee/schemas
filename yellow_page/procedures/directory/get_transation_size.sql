DELIMITER $
DROP PROCEDURE IF EXISTS `get_transation_size`$
CREATE PROCEDURE `get_transation_size`(
  IN _nodes JSON,
  IN _recipient_id VARCHAR(16),
  IN _action   VARCHAR(16)
)
BEGIN
  DECLARE _nid  VARCHAR(16) CHARACTER SET ascii ;
  DECLARE _shub_id  VARCHAR(16) CHARACTER SET ascii ;
  DECLARE _idx INT(4) DEFAULT 0; 
  DECLARE _shub_db VARCHAR(40);
  DECLARE _size DOUBLE default 0;

  WHILE _idx < JSON_LENGTH(_nodes) DO 
    SELECT get_json_array(_nodes, _idx) INTO @_node;
    SELECT get_json_object(@_node, "nid") INTO _nid;
    SELECT get_json_object(@_node, "hub_id") INTO _shub_id;
 
    IF not (_action  = 'move'  AND _shub_id = _recipient_id ) then
      SELECT db_name FROM yp.entity WHERE id = _shub_id INTO _shub_db; 
      SELECT 0 INTO @__mysize;

          SET @st = CONCAT
          (
            "WITH RECURSIVE mytree AS 
            (
              SELECT id,  parent_id ,filesize, category
              FROM  ",_shub_db,".media WHERE id = ", QUOTE(_nid) , "
                UNION ALL
              SELECT m.id, m.parent_id ,m.filesize, m.category
              FROM ",_shub_db,".media AS m JOIN mytree AS t ON m.parent_id = t.id
            )
            SELECT sum(filesize) FROM mytree INTO @__mysize;"
          );
          PREPARE stmt FROM @st;
          EXECUTE stmt ;
          DEALLOCATE PREPARE stmt;
      SELECT  IFNULL(_size,0) + IFNULL(@__mysize,0) INTO _size ;  
    END IF;

    SELECT _idx + 1 INTO _idx;
  END WHILE;


  SELECT _size size;
END$


DELIMITER ;
