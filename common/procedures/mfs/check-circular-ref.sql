DELIMITER $
-- ==============================================================
-- mfs_chk_circular_ref, find any circular refrence if move or copy a folder
-- ==============================================================
DROP PROCEDURE IF EXISTS `mfs_chk_circular_ref`$
CREATE PROCEDURE `mfs_chk_circular_ref`(
  IN _nodes MEDIUMTEXT,
  IN _uid VARCHAR(16),
  IN _dest_id VARCHAR(16),
  IN _recipient_id VARCHAR(16)
)
BEGIN
  DECLARE  _idx INT(4) DEFAULT 0; 
  DECLARE  _nid VARCHAR(16);
  DECLARE  _hub_id VARCHAR(16);
  DECLARE  _hub_db VARCHAR(40);
  DECLARE  _home_dir VARCHAR(512);
  DECLARE  _dest_db VARCHAR(40);
  DECLARE _dest_home_dir VARCHAR(512);

  DROP TABLE IF EXISTS  _src_tree_media;
  CREATE TEMPORARY TABLE _src_tree_media (
    `id`              varchar(16) NOT NULL,
    `parent_id`       varchar(16) DEFAULT NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;


  SELECT db_name,home_dir FROM yp.entity WHERE id=_recipient_id INTO _dest_db,_dest_home_dir;

  WHILE _idx < JSON_LENGTH(_nodes) DO 
    SELECT JSON_UNQUOTE(JSON_EXTRACT(_nodes, CONCAT("$[", _idx, "]"))) INTO @_node;
    SELECT JSON_UNQUOTE(JSON_EXTRACT(@_node, "$.nid")) INTO _nid;
    SELECT JSON_UNQUOTE(JSON_EXTRACT(@_node, "$.hub_id")) INTO _hub_id;

    SELECT db_name,home_dir FROM yp.entity WHERE id=_hub_id INTO _hub_db ,_home_dir;

    SET @streg = CONCAT("
      INSERT INTO _src_tree_media  WITH RECURSIVE mytree AS (
        SELECT  id,  parent_id
        FROM " , _hub_db ,".media  WHERE id = ?
        UNION 
        SELECT m.id,m.parent_id
        FROM " , _hub_db ,".media  m JOIN mytree t ON m.parent_id = t.id AND m.category <> 'hub'
      )
      SELECT 
        *
      FROM mytree;
    ");
    PREPARE stamtreg FROM @streg;
    EXECUTE stamtreg USING _nid;
    DEALLOCATE PREPARE stamtreg;
    SELECT _idx + 1 INTO _idx;
  END WHILE; 

  SELECT * from _src_tree_media where id =_dest_id ;
END $

DELIMITER ;