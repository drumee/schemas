DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_set_node_attr`$
CREATE PROCEDURE `mfs_set_node_attr`(
  IN _id    VARBINARY(16),
  IN _data  JSON,
  IN _show      BOOLEAN
)
BEGIN
  DECLARE _value VARCHAR(5000);
  DECLARE _field VARCHAR(5000);
  DECLARE _fields VARCHAR(5000);
  DECLARE _i TINYINT(4) DEFAULT 0;


  SELECT JSON_ARRAY(
    "origin_id",
    "owner_id",
    "host_id",
    "file_path",
    "user_filename",
    "parent_id",
    "parent_path",
    "extension",
    "mimetype",
    "category",
    "filesize",
    "geometry",
    "publish_time",
    "upload_time",
    "last_download",
    "download_count",
    "metadata",
    "caption",
    "status",
    "approval",
    "rank"
  ) INTO _fields;
  WHILE _i < JSON_LENGTH(_fields) DO
    SELECT read_json_array(_fields, _i) INTO _field;
    SELECT JSON_VALUE(_data, CONCAT("$.",_field)) INTO _value;
    IF _value IS NOT NULL THEN
      SET @s = CONCAT("UPDATE media SET ", _field, "=? WHERE id=", QUOTE(_id));
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _value;
      DEALLOCATE PREPARE stmt;
    END IF;
    SELECT _i + 1 INTO _i;
  END WHILE;
  IF _show THEN 
    CALL mfs_node_attr(_id);
  END IF;  

  -- SELECT * FROM media WHERE id=_id;
END$
