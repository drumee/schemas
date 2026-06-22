DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_node_in_subtree`$
CREATE PROCEDURE `mfs_node_in_subtree`(
  IN _root_nid VARCHAR(16) CHARACTER SET ascii,
  IN _nid VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  DECLARE _found INT DEFAULT 0;
  DROP TEMPORARY TABLE IF EXISTS _ancestry_tmp;
  CREATE TEMPORARY TABLE _ancestry_tmp (
    id VARCHAR(16) CHARACTER SET ascii
  );
  INSERT INTO _ancestry_tmp (id)
  WITH RECURSIVE _ancestry AS (
    SELECT id, parent_id FROM media WHERE id = _nid
    UNION ALL
    SELECT m.id, m.parent_id FROM media m
    JOIN _ancestry a ON m.id = a.parent_id
  )
  SELECT id FROM _ancestry;
  SELECT COUNT(*) INTO _found FROM _ancestry_tmp WHERE id = _root_nid;
  DROP TEMPORARY TABLE IF EXISTS _ancestry_tmp;
  SELECT IF(_found > 0, 1, 0) AS in_scope;
END$

DELIMITER ;
