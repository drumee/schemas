DELIMITER $
DROP PROCEDURE IF EXISTS `task_get_linked_files`$
CREATE PROCEDURE `task_get_linked_files`(
  IN _task_id VARCHAR(16)
)
BEGIN
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
  WHERE tf.task_id = _task_id
  ORDER BY tf.ctime ASC;
END$
DELIMITER ;