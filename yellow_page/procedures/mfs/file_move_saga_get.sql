DELIMITER $

DROP PROCEDURE IF EXISTS `file_move_saga_get`$
CREATE PROCEDURE `file_move_saga_get`(
  IN _operation_id VARCHAR(16)
)
BEGIN
  SELECT s.*,
    l.original_hub_id,
    l.original_file_nid,
    l.original_thread_id,
    l.current_hub_id,
    l.current_file_nid,
    l.current_thread_id,
    l.state AS lineage_state
  FROM file_move_saga s
  INNER JOIN file_thread_lineage l ON l.lineage_id = s.lineage_id
  WHERE s.operation_id = _operation_id
  LIMIT 1;
END $

DELIMITER ;
