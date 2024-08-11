DELIMITER $



--   NEED TO DELETE - GOPINATH 
DROP PROCEDURE IF EXISTS `mfs_trash_child_hub`$
CREATE PROCEDURE `mfs_trash_child_hub`(
  IN _nid VARCHAR(16),
  IN _uid VARCHAR(16),
  OUT _output VARCHAR(1000)
)
BEGIN
  DECLARE _tempid VARCHAR(16);

  DECLARE _owner_id VARCHAR(16);
  DECLARE _node_hub_db VARCHAR(40);
  DECLARE _user_hub_db VARCHAR(40);
  DECLARE _cum_output MEDIUMTEXT;
  DROP TABLE IF EXISTS _myhub; 
  CREATE TEMPORARY TABLE `_myhub` (
      id varchar(16) DEFAULT NULL,
    is_checked boolean default 0
  );              

  INSERT INTO _myhub (id ,is_checked ) 
  WITH RECURSIVE myhub AS (
  SELECT id, category  , _nid nid FROM media WHERE id = _nid
  UNION ALL
  SELECT m.id,m.category, t.nid 
  FROM media AS m JOIN myhub AS t ON m.parent_id =t.id
  )
  SELECT id,0 FROM myhub WHERE  category ='hub';

  SELECT `db_name` FROM yp.entity WHERE id = _uid INTO _user_hub_db;                

  SELECT  id FROM _myhub where is_checked =0 LIMIT 1 INTO _tempid ;

  
  WHILE (_tempid IS NOT NULL) do
    SELECT owner_id FROM yp.hub WHERE id = _tempid INTO _owner_id;
    SELECT `db_name` FROM yp.entity WHERE id = _tempid INTO _node_hub_db;

    IF _uid = _owner_id THEN
      SET @sql = CONCAT(
        "CALL  ", _node_hub_db, ".remove_all_members (", quote(_owner_id), ")" );
      PREPARE hub_stmt FROM @sql;
      EXECUTE hub_stmt;
      DEALLOCATE PREPARE hub_stmt;
    ELSE 

      SET @sql = CONCAT(
        "CALL  ", _user_hub_db, ".leave_hub (", quote(_tempid), ")" );
      PREPARE hub_stmt FROM @sql;
      EXECUTE hub_stmt;
      DEALLOCATE PREPARE hub_stmt;

      SET @sql = CONCAT("CALL  " , _node_hub_db ,".hub_add_action_log (?,?,?,?,?,?)");
      PREPARE hub_stmt FROM @sql;
      EXECUTE hub_stmt USING _tempid,'left','member','admin',null,'has been left';
      DEALLOCATE PREPARE hub_stmt;



      SELECT NULL  INTO @huboutput;
      SET @sql = CONCAT(
        " SELECT user_filename FROM ", _user_hub_db, ".media where id= ", quote(_tempid), "INTO @child_hub" );
      PREPARE hub_stmt FROM @sql;
      EXECUTE hub_stmt;
      DEALLOCATE PREPARE hub_stmt;

      SELECT 
        CASE 
        WHEN _cum_output IS NOT NULL  AND @child_hub IS NOT NULL     THEN CONCAT (_cum_output ,',',@child_hub )
        WHEN _cum_output IS NULL      AND @child_hub IS NOT NULL     THEN @child_hub 
        WHEN _cum_output IS NOT NULL  AND @child_hub IS NULL         THEN _cum_output
        WHEN _cum_output IS NULL      AND @child_hub IS NULL         THEN NULL
        END
      INTO _cum_output;

    END IF;
    UPDATE _myhub SET is_checked = 1 WHERE id = _tempid ;
    SELECT NULL INTO _tempid ;
    SELECT id FROM _myhub WHERE is_checked =0 LIMIT 1 INTO _tempid ;

  END WHILE;

  SELECT _cum_output  INTO _output;

  DROP TABLE IF EXISTS _myhub;

END $


DELIMITER ;
