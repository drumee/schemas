DELIMITER $

DROP PROCEDURE IF EXISTS `seo_update_hub`$
CREATE PROCEDURE `seo_update_hub`(
  IN _old_hub_id VARCHAR(16),
  IN _new_hub_id VARCHAR(16),
  IN _nid VARCHAR(16)
)
BEGIN
  DECLARE _updated_words INT DEFAULT 0;
  DECLARE _updated_register INT DEFAULT 0;
  
  -- Update hub_id in seo_index
  UPDATE seo_index 
  SET hub_id = _new_hub_id 
  WHERE hub_id = _old_hub_id AND nid = _nid;
  
  SET _updated_words = ROW_COUNT();
  
  -- Update hub_id in seo_register
  UPDATE seo_register 
  SET hub_id = _new_hub_id 
  WHERE hub_id = _old_hub_id AND nid = _nid;
  
  SET _updated_register = ROW_COUNT();
  
  SELECT 
    _updated_words AS updated_words,
    _updated_register AS updated_register,
    'success' AS status;
END$

DELIMITER ;