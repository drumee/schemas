DELIMITER $

DROP PROCEDURE IF EXISTS `seo_delete_index`$
CREATE PROCEDURE `seo_delete_index`(
  IN _hub_id VARCHAR(16),
  IN _nid VARCHAR(16)
)
BEGIN
  DECLARE _deleted_words INT DEFAULT 0;
  DECLARE _deleted_register INT DEFAULT 0;
  
  -- Delete indexed words
  DELETE FROM seo_index 
  WHERE hub_id = _hub_id AND nid = _nid;
  
  SET _deleted_words = ROW_COUNT();
  
  -- Delete from register
  DELETE FROM seo_register
  WHERE hub_id = _hub_id AND nid = _nid;
  
  SET _deleted_register = ROW_COUNT();
  
  -- Return count (for logging/debugging)
  SELECT 
    _deleted_words AS deleted_words,
    _deleted_register AS deleted_register,
    'success' AS status;
END$

DELIMITER ;