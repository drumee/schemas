DELIMITER $

-- =========================================================
-- task_comment_link_file
-- =========================================================
DROP PROCEDURE IF EXISTS `task_comment_link_file`$
CREATE PROCEDURE `task_comment_link_file`(
  IN _comment_id VARCHAR(16),
  IN _file_nid VARCHAR(16),
  IN _linked_by VARCHAR(16)
)
BEGIN
  -- INSERT IGNORE, like task_link_file: the client links each dropped file
  -- independently, and a retried call must not fail the save.
  INSERT IGNORE INTO task_comment_file (comment_id, file_nid, linked_by, ctime)
  VALUES (_comment_id, _file_nid, _linked_by, UNIX_TIMESTAMP());

  -- Return the comment's full attachment list, shaped like the `attachments`
  -- array task_comment_list emits, so the caller can hand it straight back.
  SELECT
    cf.comment_id,
    cf.file_nid,
    cf.linked_by,
    cf.ctime,
    m.user_filename AS filename,
    m.category,
    m.extension,
    m.filesize
  FROM task_comment_file cf
  LEFT JOIN media m ON m.id = cf.file_nid
  WHERE cf.comment_id = _comment_id
  ORDER BY cf.ctime ASC;
END $

DELIMITER ;
