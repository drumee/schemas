DELIMITER $

DROP PROCEDURE IF EXISTS `file_thread_lineage_resolve`$
CREATE PROCEDURE `file_thread_lineage_resolve`(
  IN _hub_id VARCHAR(16),
  IN _file_nid VARCHAR(16)
)
BEGIN
  SELECT
    l.lineage_id,
    l.original_hub_id,
    l.original_file_nid,
    l.original_thread_id,
    l.current_hub_id,
    l.current_file_nid,
    l.current_thread_id,
    l.current_operation_id,
    l.access_revision,
    l.state
  FROM file_thread_lineage l
  WHERE l.current_hub_id = _hub_id AND l.current_file_nid = _file_nid
  LIMIT 1;
END $

DELIMITER ;
