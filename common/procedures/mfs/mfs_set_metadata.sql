DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_set_metadata`$
CREATE PROCEDURE `mfs_set_metadata`(
  IN _id        VARCHAR(16),
  IN _value     JSON,
  IN _show_res BOOLEAN    
)
BEGIN

  DECLARE _idx INTEGER DEFAULT 0;
  DECLARE _key VARCHAR(100);
  DECLARE _val JSON;

  IF JSON_VALID(_value) THEN
    SELECT JSON_KEYS(_value) INTO @_keys;
    WHILE _idx < JSON_LENGTH(@_keys) DO
      SELECT JSON_VALUE(@_keys, CONCAT("$[", _idx, "]")) INTO _key;
      SELECT IFNULL( JSON_VALUE(_value, CONCAT("$.", _key)) , JSON_QUERY(_value, CONCAT("$.", _key))) INTO _val;

      IF _key = "fingerprint"  AND  _val <> '' THEN
        SELECT sha2(_val, 512) INTO _val;
      END IF;
      IF _key = "expiry" THEN
        SELECT IF(IFNULL(_val, 0) = 0, 0,
          UNIX_TIMESTAMP(TIMESTAMPADD(HOUR,_val, FROM_UNIXTIME(UNIX_TIMESTAMP())))) INTO _val;
      END IF;
     
      UPDATE media SET metadata=JSON_SET(
        IF(JSON_VALID(metadata), metadata, "{}"), CONCAT("$.", _key), _val) WHERE id=_id;
      SELECT _idx + 1 INTO _idx;
    END WHILE;
  END IF;

  UPDATE media SET publish_time = UNIX_TIMESTAMP() WHERE id=_id;

  IF _show_res THEN
    CALL mfs_node_attr(_id);
  END IF;

END $
    


DELIMITER ;