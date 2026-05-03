DELIMITER $
DROP PROCEDURE IF EXISTS `task_list`$
CREATE PROCEDURE `task_list`()
BEGIN
  SELECT
    t.id,
    t.title,
    t.description,
    t.status,
    t.priority,
    t.due_date,
    t.created_by,
    t.assignee_uid,
    t.rank,
    t.ctime,
    t.mtime,
    GROUP_CONCAT(tl.label_id) AS label_ids,
    COALESCE((
      SELECT JSON_ARRAYAGG(
        JSON_OBJECT(
          'nid',       tf.file_nid,
          'filename',  m.user_filename,
          'extension', m.extension,
          'category',  m.category
        )
      )
      FROM task_file tf
      LEFT JOIN media m ON m.id = tf.file_nid
      WHERE tf.task_id = t.id
    ), JSON_ARRAY()) AS linked_files
  FROM task t
  LEFT JOIN task_label tl ON tl.task_id = t.id
  GROUP BY t.id
  ORDER BY
    FIELD(t.status, 'todo', 'in_progress', 'to_review', 'complete'),
    t.rank ASC,
    t.ctime ASC;
END$
DELIMITER ;
