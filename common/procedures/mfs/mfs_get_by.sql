DELIMITER $
-- ===============================================
DROP PROCEDURE IF EXISTS `mfs_get_by`$
CREATE PROCEDURE `mfs_get_by`(
  IN _nid VARCHAR(16)
)
BEGIN
    WITH RECURSIVE _tree AS
    (
      SELECT
        m.id, 
        m.id top_id, 
        m.filesize,
        m.parent_id
      FROM
        media m
        WHERE m.parent_id =  _nid AND status='active'
      UNION ALL
        SELECT
        m.id, 
        t.top_id,
        m.filesize,
        m.parent_id      
      FROM
        media  m
      INNER JOIN _tree  t ON m.parent_id = t.id
        AND m.status='active'
    )
    SELECT 
        m.id AS nid,
        s.filesize,
        m.parent_id AS pid,
        m.user_filename  filename,
        m.file_path as filepath,
        m.extension AS ext,
        m.category AS ftype,
        m.category AS filetype,
        m.upload_time AS ctime,
        m.publish_time AS mtime
    FROM media m
    INNER JOIN 
      (SELECT
         top_id id , sum(filesize) filesize  
      FROM _tree GROUP BY   top_id 
      ) s  ON s.id = m.id 
    WHERE m.parent_id =_nid;

END$

DELIMITER ;
