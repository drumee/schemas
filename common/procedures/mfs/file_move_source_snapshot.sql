DELIMITER $

DROP PROCEDURE IF EXISTS `file_move_source_snapshot`$
CREATE PROCEDURE `file_move_source_snapshot`(
  IN _actor_id VARCHAR(16),
  IN _file_nid VARCHAR(16)
)
BEGIN
  SELECT
    m.id AS file_nid,
    m.parent_id AS parent_nid,
    m.category,
    m.status AS media_status,
    m.user_filename,
    m.filesize,
    user_permission(_actor_id, m.id) AS permission,
    ft.root_message_id AS file_thread_id,
    ft.created_by AS thread_created_by,
    ft.reply_count,
    ft.ctime AS thread_ctime,
    ft.mtime AS thread_mtime,
    e.id AS hub_id,
    e.db_name,
    CONCAT(e.home_dir, '/__storage__/') AS mfs_root
  FROM media m
  INNER JOIN yp.entity e ON e.db_name = DATABASE()
  LEFT JOIN file_thread ft ON ft.file_nid = m.id AND ft.status = 'active'
  WHERE m.id = _file_nid AND m.status NOT IN ('hidden','deleted')
  LIMIT 1;
END $

DELIMITER ;
