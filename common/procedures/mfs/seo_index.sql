DELIMITER $

DROP PROCEDURE IF EXISTS `seo_index`$
CREATE PROCEDURE `seo_index`(
	IN _data  JSON
)
BEGIN
  DECLARE _i INTEGER DEFAULT 0;
  WHILE _i < JSON_LENGTH(_data) DO 
    SELECT read_json_array(_data, _i) INTO @_item;
      -- INSERT IGNORE INTO seo SELECT null, JSON_VALUE(_data), _hub_id, _nid;
    
    INSERT INTO seo_index SELECT 
      null,
      JSON_VALUE(@_item, "$.nid"),
      JSON_VALUE(@_item, "$.hub_id"),
      JSON_VALUE(@_item, "$.word"),
      0,
      1,
      UNIX_TIMESTAMP()
    ON DUPLICATE KEY UPDATE 
      frequency = frequency + 1,
      created_at = UNIX_TIMESTAMP();
    
    SELECT _i + 1 INTO _i;
  END WHILE;
END$


DROP PROCEDURE IF EXISTS `seo_index_bulk`$
CREATE PROCEDURE `seo_index_bulk`(
	IN _data  mediumtext
)
BEGIN
  SET @st = _data;
  PREPARE stmt2 FROM @st;
  EXECUTE stmt2 ;           
  DEALLOCATE PREPARE stmt2;
END$


DELIMITER ;
