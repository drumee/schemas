DELIMITER $

DROP PROCEDURE IF EXISTS `seo_search_unified`$
CREATE PROCEDURE `seo_search_unified`(
  IN _hub_id VARCHAR(16),
  IN _uid VARCHAR(16),
  IN _query TEXT,
  IN _page INT,
  IN _limit INT
)
BEGIN
  DECLARE _offset INT;
  DECLARE _home_dir VARCHAR(512);
  DECLARE _vhost VARCHAR(255);
  DECLARE _xhub_name VARCHAR(512);
  
  SET _offset = (_page - 1) * _limit;
  
  -- Get hub info
  SELECT home_dir, vhost(id) 
  FROM yp.entity 
  WHERE id = _hub_id 
  INTO _home_dir, _vhost;
  
  -- Get xhub_name
  SELECT '' INTO _xhub_name;
  SELECT db_name FROM yp.entity WHERE id = _uid INTO @_user_db_name;
  IF @_user_db_name IS NOT NULL THEN 
    SET @s = CONCAT("SELECT ", @_user_db_name, ".filepath(?) INTO @xhub_name");
    PREPARE stmt FROM @s;
    EXECUTE stmt USING _hub_id;
    DEALLOCATE PREPARE stmt;
    SELECT @xhub_name INTO _xhub_name;
  END IF;
  
  -- Temp table for search terms (normalized)
  DROP TEMPORARY TABLE IF EXISTS _search_terms;
  CREATE TEMPORARY TABLE _search_terms (
    term VARCHAR(255),
    INDEX(term)
  ) ENGINE=MEMORY;
  
  -- Split query into words (handle up to 20 words)
  INSERT INTO _search_terms
  SELECT DISTINCT LOWER(TRIM(term))
  FROM (
    SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(_query, ' ', n), ' ', -1) AS term
    FROM (
      SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
      UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8
      UNION SELECT 9 UNION SELECT 10 UNION SELECT 11 UNION SELECT 12
      UNION SELECT 13 UNION SELECT 14 UNION SELECT 15 UNION SELECT 16
      UNION SELECT 17 UNION SELECT 18 UNION SELECT 19 UNION SELECT 20
    ) numbers
    WHERE n <= 1 + (LENGTH(_query) - LENGTH(REPLACE(_query, ' ', '')))
  ) terms
  WHERE LENGTH(TRIM(term)) >= 2;
  
  -- Main search query with scoring
  SELECT 
    m.id AS nid,
    m.id,
    m.parent_id,
    m.parent_id AS pid,
    CONCAT(_home_dir, "/__storage__/") AS mfs_root,
    _hub_id AS hub_id,
    _hub_id AS holder_id,
    _vhost AS vhost,
    user_permission(_uid, m.id) AS privilege,
    m.owner_id,
    m.user_filename AS filename,
    m.user_filename,
    m.file_path AS ownpath,
    CONCAT(_xhub_name, m.file_path) AS file_path,
    CONCAT(_xhub_name, m.file_path) AS filepath,
    m.filesize,
    m.extension,
    m.extension AS ext,
    m.category AS ftype,
    m.category AS filetype,
    m.category,
    m.mimetype,
    m.geometry,
    m.upload_time AS ctime,
    m.publish_time AS mtime,
    m.parent_path,
    m.metadata,
    database() AS db_name,
    -- Relevance scoring
    (
      -- Exact filename match: 1000 points
      (CASE WHEN LOWER(m.user_filename) LIKE CONCAT('%', LOWER(_query), '%') THEN 1000 ELSE 0 END) +
      
      -- Filename contains any search term: 500 points per term
      (
        SELECT IFNULL(SUM(500), 0)
        FROM _search_terms st
        WHERE LOWER(m.user_filename) LIKE CONCAT('%', st.term, '%')
      ) +
      
      -- Extension matches: 300 points
      (CASE WHEN LOWER(m.extension) IN (SELECT term FROM _search_terms) THEN 300 ELSE 0 END) +
      
      -- Indexed content match: 10 points per unique matching word
      IFNULL((
        SELECT COUNT(DISTINCT st.term) * 10
        FROM _search_terms st
        INNER JOIN seo_index si ON si.word = st.term 
          AND si.nid = m.id 
          AND si.hub_id = _hub_id
      ), 0)
    ) AS relevance_score
    
  FROM media m
  WHERE m.status = 'active'
    AND m.category NOT IN ('hub', 'root')
    AND (
      -- Filename matches query
      LOWER(m.user_filename) LIKE CONCAT('%', LOWER(_query), '%')
      
      OR
      
      -- Filename matches any search term
      EXISTS(
        SELECT 1 FROM _search_terms st
        WHERE LOWER(m.user_filename) LIKE CONCAT('%', st.term, '%')
      )
      
      OR
      
      -- Extension matches
      LOWER(m.extension) IN (SELECT term FROM _search_terms)
      
      OR
      
      -- Indexed content matches
      m.id IN (
        SELECT DISTINCT si.nid 
        FROM seo_index si
        INNER JOIN _search_terms st ON si.word = st.term
        WHERE si.hub_id = _hub_id
      )
    )
  
  HAVING relevance_score > 0
  ORDER BY relevance_score DESC, m.publish_time DESC
  LIMIT _limit OFFSET _offset;
  
  DROP TEMPORARY TABLE IF EXISTS _search_terms;
END$

DELIMITER ;