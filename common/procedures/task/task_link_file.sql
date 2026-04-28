DELIMITER $
DROP PROCEDURE IF EXISTS `task_link_file`$
CREATE PROCEDURE `task_link_file`(
  IN _task_id VARCHAR(16),
  IN _file_nid VARCHAR(16),
  IN _linked_by VARCHAR(16)
)
BEGIN
  INSERT IGNORE INTO task_file (task_id, file_nid, linked_by, ctime)
  VALUES (_task_id, _file_nid, _linked_by, UNIX_TIMESTAMP());

  -- Return updated linked files list for this task
  SELECT
    tf.task_id,
    tf.file_nid,
    tf.linked_by,
    tf.ctime,
    m.user_filename AS filename,
    m.category,
    m.extension,
    m.filesize
  FROM task_file tf
  LEFT JOIN media m ON m.id = tf.file_nid
  WHERE tf.task_id = _task_id;
END$
DELIMITER ;