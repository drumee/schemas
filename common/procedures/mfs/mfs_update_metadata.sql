DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_update_metadata`$
CREATE PROCEDURE `mfs_update_metadata`(
  IN _id    VARBINARY(16),
  IN _data  JSON
)
BEGIN
  DECLARE _value mediumtext;
  DECLARE _path VARCHAR(5000);
  DECLARE _paths VARCHAR(5000);
  DECLARE _i TINYINT(4) DEFAULT 0;


  SELECT JSON_ARRAY(
    "sharebox",
    "branch",
    "fingerprint",
    "expiry",
    "email",
    "message",
    "otp",
    "otp_mail",
    "otp_mail_verified",
    "sender_lang"
  ) INTO _paths;
  WHILE _i < JSON_LENGTH(_paths) DO
    SELECT read_json_array(_paths, _i) INTO _path;
    SELECT get_json_object(_data, _path) INTO _value;
    IF _value IS NOT NULL THEN
      IF _path = "fingerprint"  AND  _value <> '' THEN
        SELECT sha2(_value, 512) INTO _value;
      END IF;
      IF _path = "expiry" THEN
        SELECT IF(IFNULL(_value, 0) = 0, 0,
          UNIX_TIMESTAMP(TIMESTAMPADD(HOUR,_value, FROM_UNIXTIME(UNIX_TIMESTAMP())))) INTO _value;
       END IF;
      UPDATE media SET `metadata` =
        JSON_SET( IFNULL(metadata, '{}'), CONCAT("$.",_path), _value) WHERE id=_id;
    END IF;
    SELECT _i + 1 INTO _i;
  END WHILE;
  SELECT * FROM media WHERE id=_id;
END$



