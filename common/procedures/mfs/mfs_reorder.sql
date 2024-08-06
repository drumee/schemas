DELIMITER $


-- =======================================================================
-- mfs_update_rank
-- =======================================================================
DROP PROCEDURE IF EXISTS `mfs_reorder`$
CREATE PROCEDURE `mfs_reorder`(
  IN _nodes JSON
)
BEGIN
  DECLARE _i INTEGER DEFAULT 0;
  DROP TABLE IF EXISTS __tmp_rank;
  CREATE TEMPORARY TABLE __tmp_rank(
    `rank` INTEGER,
    `id` varchar(16) CHARACTER SET utf8
  ); 

  WHILE _i < JSON_LENGTH(_nodes) DO 
     UPDATE media SET rank = _i 
       WHERE id = JSON_UNQUOTE(JSON_EXTRACT(_nodes, CONCAT("$[", _i, "]")));
    INSERT INTO __tmp_rank 
      SELECT _i, JSON_VALUE(_nodes, CONCAT("$[", _i, "]"));
    SELECT _i + 1 INTO _i;
  END WHILE;

  SELECT * FROM __tmp_rank;
END $

DELIMITER ;

