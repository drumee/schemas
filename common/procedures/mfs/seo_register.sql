DELIMITER $

DROP PROCEDURE IF EXISTS `seo_register`$
CREATE PROCEDURE `seo_register`(
	IN _hub_id VARCHAR(16),
	IN _nid VARCHAR(16),
	IN _node JSON
)
BEGIN
  REPLACE INTO seo_object SELECT 
    null,
    _hub_id, 
    _nid,
    _node;
END$

DELIMITER ;
