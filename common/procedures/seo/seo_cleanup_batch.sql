DELIMITER $

DROP PROCEDURE IF EXISTS `seo_cleanup_batch`$
CREATE PROCEDURE `seo_cleanup_batch`(
  IN _hub_id VARCHAR(16),
  IN _nids JSON
)
BEGIN
  DECLARE _idx INT DEFAULT 0;
  DECLARE _nid VARCHAR(16);
  DECLARE _total_deleted INT DEFAULT 0;
  
  -- Temp table for batch delete
  DROP TEMPORARY TABLE IF EXISTS _cleanup_list;
  CREATE TEMPORARY TABLE _cleanup_list (
    nid VARCHAR(16),
    INDEX(nid)
  ) ENGINE=MEMORY;
  
  -- Parse JSON array into temp table
  WHILE _idx < JSON_LENGTH(_nids) DO
    SELECT JSON_UNQUOTE(JSON_EXTRACT(_nids, CONCAT('$[', _idx, ']'))) INTO _nid;
    INSERT INTO _cleanup_list VALUES (_nid);
    SELECT _idx + 1 INTO _idx;
  END WHILE;
  
  -- Batch delete from seo_index
  DELETE si FROM seo_index si
  INNER JOIN _cleanup_list cl ON si.nid = cl.nid
  WHERE si.hub_id = _hub_id;
  
  SET _total_deleted = ROW_COUNT();
  
  -- Batch delete from seo_register
  DELETE sr FROM seo_register sr
  INNER JOIN _cleanup_list cl ON sr.nid = cl.nid
  WHERE sr.hub_id = _hub_id;
  
  DROP TEMPORARY TABLE IF EXISTS _cleanup_list;
  
  -- SELECT 
  --   _total_deleted AS deleted_count,
  --   'success' AS status;
END$

DELIMITER ;