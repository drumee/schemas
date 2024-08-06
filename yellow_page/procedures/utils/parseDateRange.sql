DELIMITER $

DROP PROCEDURE IF EXISTS `parseDateRange`$
CREATE PROCEDURE `parseDateRange`(
  IN _json json,
  OUT _format VARCHAR(120),
  OUT _start_time int(11) unsigned,
  OUT _end_time int(11) unsigned
)
BEGIN
  DECLARE _start VARCHAR(120);
  DECLARE _end VARCHAR(120);
  DECLARE _periode int(11) unsigned;
  DECLARE _epoch VARCHAR(120);

  SELECT IFNULL(json_value(_json, "$.time_format"), "%y-%m-%d") INTO _format;
  SELECT IFNULL(JSON_VALUE(_json, "$.periode"), 60*60*24) INTO _periode;

  SELECT json_value(_json, "$.start") INTO _start;

  SELECT IFNULL(JSON_VALUE(_json, "$.drumee_epoch"), '2021-01-01') INTO _epoch;

  IF _start IS NULL THEN 
    SELECT UNIX_TIMESTAMP() - _periode INTO _start_time;
  ELSE 
    SELECT UNIX_TIMESTAMP(STR_TO_DATE(_start, _format)) INTO _start_time;
  END IF;

  IF UNIX_TIMESTAMP(STR_TO_DATE(_epoch , "%Y-%m-%d")) > _start_time THEN
    SELECT UNIX_TIMESTAMP(STR_TO_DATE(_epoch , "%Y-%m-%d"))  INTO _start_time;
  END IF;

  SELECT json_value(_json, "$.end") INTO _end;
  IF _end IS NULL THEN 
    SELECT UNIX_TIMESTAMP() INTO _end_time;
  ELSE
    SELECT UNIX_TIMESTAMP(STR_TO_DATE(_end, _format)) INTO _end_time;
  END IF;

  
  IF _end_time < _start_time THEN 
    SELECT _start_time + _periode INTO _end_time;
  END IF;

END $

DELIMITER ;