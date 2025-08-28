DELIMITER $
DROP PROCEDURE IF EXISTS `get_quota`$
CREATE PROCEDURE `get_quota`(
  IN _args TEXT
)
BEGIN
  DECLARE _domain_id INTEGER;
  DECLARE _category VARCHAR(512) CHARACTER SET ascii COLLATE ascii_general_ci;
  DECLARE _email VARCHAR(512) CHARACTER SET ascii COLLATE ascii_general_ci;
  DECLARE _id VARCHAR(512) CHARACTER SET ascii COLLATE ascii_general_ci;
  DECLARE _domain VARCHAR(512) CHARACTER SET ascii COLLATE ascii_general_ci;
  DECLARE _username VARCHAR(128) CHARACTER SET ascii COLLATE ascii_general_ci;
  DECLARE _res JSON;
  DECLARE _quota JSON;


  SELECT IFNULL(JSON_VALUE(profile, "$.category"), "default"), IFNULL(quota, "{}")
  FROM drumate WHERE id=_args OR email=_args 
    INTO _category, _quota;
  
  SELECT 
    category,
    COALESCE(JSON_VALUE(_quota, "$.private_hub"), private_hub) private_hub,
    COALESCE(JSON_VALUE(_quota, "$.share_hub"), share_hub) share_hub ,
    COALESCE(JSON_VALUE(_quota, "$.public_hub"), public_hub) public_hub,
    COALESCE(JSON_VALUE(_quota, "$.disk"), desk_disk) storage,
    COALESCE(JSON_VALUE(_quota, "$.organization"), organization) organization,
    COALESCE(JSON_VALUE(_quota, "$.meeting_call"), conference) conference
  FROM group_quota WHERE category=_category;
END$
DELIMITER ;
