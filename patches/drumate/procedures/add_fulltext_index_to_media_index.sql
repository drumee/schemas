-- File: patches/drumate/procedures/add_fulltext_index_to_media_index.sql
-- Purpose: Add full text index for better search performance

-- To check if index was created:
-- SHOW INDEX FROM media_index WHERE Key_name = 'idx_fulltext_search';

-- To test:
-- SELECT filename FROM media_index 
-- WHERE MATCH(filename, filepath) AGAINST('your search term' IN NATURAL LANGUAGE MODE);

ALTER TABLE media_index 
ADD FULLTEXT INDEX idx_fulltext_search (filename, filepath);