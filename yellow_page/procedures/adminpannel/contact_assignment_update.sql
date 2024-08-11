DELIMITER $


DROP PROCEDURE IF EXISTS `contact_assignment_update`$
CREATE PROCEDURE `contact_assignment_update`(
  IN _owner_id VARCHAR(16),
  IN _members JSON
)
BEGIN
  DECLARE _idx INTEGER DEFAULT 0;
  DECLARE _member_id VARCHAR(16);
  DECLARE _length INTEGER DEFAULT 0;
  DECLARE _sys_id INT DEFAULT 0;
  DECLARE _temp_sys_id INT;
  DECLARE _db VARCHAR(1000) ;

  IF _members IN ('',  '0') THEN 
   SELECT NULL INTO  _members;
  END IF;
  
  DROP TABLE IF EXISTS _contact_sync;
  CREATE TEMPORARY TABLE _contact_sync AS SELECT * FROM contact_sync WHERE (owner_id = _owner_id OR uid = _owner_id);

  SELECT  JSON_LENGTH(_members)  INTO _length;

  WHILE _idx < _length  DO 
    SELECT JSON_UNQUOTE(JSON_EXTRACT(_members, CONCAT("$[", _idx, "]"))) INTO _member_id;

    INSERT INTO contact_sync(owner_id,uid,status) 
    SELECT _member_id,_owner_id,'new' ON DUPLICATE KEY UPDATE status = CASE WHEN status ='delete' THEN 'new' ELSE status END ;

    INSERT INTO contact_sync(owner_id,uid,status) 
    SELECT _owner_id,_member_id,'new' ON DUPLICATE KEY UPDATE status = CASE WHEN status ='delete' THEN 'new' ELSE status END ;

    DELETE FROM _contact_sync WHERE owner_id = _owner_id AND uid = _member_id;

    DELETE FROM _contact_sync WHERE uid = _owner_id AND owner_id = _member_id;

    SELECT _idx + 1 INTO _idx;
  END WHILE;

  UPDATE contact_sync o 
  INNER JOIN  _contact_sync t   ON o.owner_id = t.owner_id AND o.uid = t.uid 
  SET o.status ='delete';
 
  SELECT sys_id,uid  FROM contact_sync WHERE sys_id > 0  AND owner_id = _owner_id ORDER BY sys_id ASC LIMIT 1 INTO _sys_id ,_member_id;

  WHILE _sys_id <> 0 DO
    SELECT  NULL INTO _db;
    SELECT db_name FROM entity WHERE id = _member_id AND status <> 'deleted'  INTO _db;
    IF _db IS NOT NULL THEN
      SET @st = CONCAT("CALL  " , _db ,".my_contact_sync(?)");
      PREPARE stamt FROM @st;
      EXECUTE stamt USING _member_id;
      DEALLOCATE PREPARE stamt;
    END IF ;
    SELECT _sys_id INTO  _temp_sys_id ;  
    SELECT 0 ,NULL INTO  _sys_id,_member_id ; 
    SELECT IFNULL(sys_id,0),uid FROM contact_sync WHERE sys_id > _temp_sys_id  AND owner_id = _owner_id ORDER BY sys_id ASC LIMIT 1 INTO _sys_id,_member_id;
  END WHILE;

  SELECT  NULL INTO _db;
  SELECT db_name FROM entity WHERE id = _owner_id  AND status <> 'deleted' INTO _db;
  IF _db IS NOT NULL THEN
    SET @st = CONCAT("CALL  " , _db ,".my_contact_sync(?)");
    PREPARE stamt FROM @st;
    EXECUTE stamt USING _owner_id;
    DEALLOCATE PREPARE stamt;
  END IF ;

  SELECT * FROM contact_sync WHERE owner_id = _owner_id;
END$

DELIMITER ;
