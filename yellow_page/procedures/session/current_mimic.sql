DELIMITER $

DROP PROCEDURE IF EXISTS `current_mimic`$
CREATE PROCEDURE `current_mimic`(
  IN _sid VARCHAR(90)
)
BEGIN
  DECLARE _mimic_type VARCHAR(30) default  'normal';
  DECLARE _mimicker VARCHAR(64);
  DECLARE _mimic_id VARCHAR(16);
  DECLARE _mimic_entity JSON;
  DECLARE _estimatetime INT(11);
  DECLARE _uid VARCHAR(16);

  SELECT `uid` FROM cookie WHERE id=_sid INTO  _uid; 

  SELECT 'victim', mimicker, id,estimatetime 
    FROM mimic WHERE status = 'active' AND uid = _uid 
    INTO  _mimic_type , _mimicker, _mimic_id ,_estimatetime ;
  SELECT 'old', mimicker, id ,estimatetime 
    FROM mimic WHERE status = 'active' AND mimicker = _uid  
    INTO  _mimic_type , _mimicker, _mimic_id , _estimatetime;
  SELECT 'mimic', m.mimicker, m.id ,estimatetime 
    FROM mimic m
    INNER JOIN cookie c ON  m.uid = c.uid AND m.mimicker = c.mimicker 
    WHERE m.status ='active' AND  c.id = _sid AND c.uid = _uid 
    INTO _mimic_type ,_mimicker, _mimic_id, _estimatetime;

  --  if oldmimc , then change it to normal.
  IF _mimic_type = 'old' AND  _estimatetime+10 <= UNIX_TIMESTAMP()  THEN 
    UPDATE mimic SET status = 'endbytime'  WHERE id = _mimic_id;
    UPDATE mimic SET metadata=JSON_MERGE(IFNULL(metadata, '{}'), JSON_OBJECT('endbytime',  UNIX_TIMESTAMP())) WHERE id=_mimic_id;
    UPDATE cookie SET uid=_mimicker , mimicker=null WHERE mimicker=_mimicker ;
    SELECT 'normal',NULL,NULL,NULL INTO _mimic_type, _mimicker, _mimic_id , _estimatetime ; 
  END IF;

    --  check time.
  IF _mimic_type = 'victim'  AND  _estimatetime+10 <= UNIX_TIMESTAMP()  THEN 
    UPDATE mimic SET status = 'endbytime'  WHERE id = _mimic_id;
    UPDATE mimic SET metadata=JSON_MERGE(IFNULL(metadata, '{}'), JSON_OBJECT('endbytime',  UNIX_TIMESTAMP())) WHERE id=_mimic_id;
    UPDATE cookie SET uid=_mimicker , mimicker=null WHERE mimicker=_mimicker ;
    SELECT 'normal',NULL,NULL,NULL INTO _mimic_type, _mimicker, _mimic_id , _estimatetime ; 
  END IF;

  SELECT _mimicker mimicker,
    _mimic_id mimic_id,
    _mimic_type mimic_type,
    _estimatetime mimic_end_at;
END$


DELIMITER ;