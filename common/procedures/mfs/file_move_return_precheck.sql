DELIMITER $

DROP PROCEDURE IF EXISTS `file_move_return_precheck`$
CREATE PROCEDURE `file_move_return_precheck`(
  IN _old_file_nid VARCHAR(16)
)
BEGIN
  SELECT
    EXISTS(SELECT 1 FROM media WHERE id = _old_file_nid) AS old_node_available,
    EXISTS(SELECT 1 FROM trash_media WHERE id = _old_file_nid) AS old_node_trashed,
    EXISTS(SELECT 1 FROM file_thread WHERE file_nid = _old_file_nid AND status = 'active')
      AS old_thread_present;
END $

DELIMITER ;
