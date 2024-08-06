DELIMITER $

-- =======================================================================
-- 
-- =======================================================================
DROP PROCEDURE IF EXISTS `mfs_clear_notification`$
CREATE PROCEDURE `mfs_clear_notification`(
  IN _id     VARCHAR(16),
  IN _uid    VARCHAR(16),
  IN _show_results BOOLEAN
)
BEGIN
  DECLARE _md JSON;
  DECLARE _cat VARCHAR(100);
  DECLARE _seen INT(11) DEFAULT NULL;
  SELECT metadata, category FROM media WHERE id=_id INTO _md, _cat;
  IF _cat = 'folder' THEN
    DROP TABLE IF EXISTS _innerfile; 
    CREATE TEMPORARY TABLE `_innerfile` (
      seq  int NOT NULL AUTO_INCREMENT,
      id varchar(16) DEFAULT NULL, 
      parent_id varchar(16) DEFAULT NULL, 
      PRIMARY KEY `seq`(`seq`)  
    );
    INSERT INTO _innerfile (id, parent_id) 
      WITH RECURSIVE myfile AS 
      (
        SELECT id, parent_id
          FROM media WHERE id = _id AND file_path not REGEXP '^/__(chat|trash)__' 
        UNION ALL
        SELECT m.id, m.parent_id
          FROM media AS m JOIN myfile AS t ON m.parent_id =t.id 
            WHERE m.parent_id !='0' AND m.file_path not REGEXP '^/__(chat|trash)__' 
      )
    SELECT id, parent_id FROM myfile;
    UPDATE media m INNER JOIN _innerfile ii USING(id) SET 
      metadata=IF(JSON_VALID(metadata), 
        JSON_REPLACE(metadata, CONCAT("$._seen_.", _uid), UNIX_TIMESTAMP()),
        JSON_OBJECT('_seen_', JSON_OBJECT(_uid, UNIX_TIMESTAMP()))
      );

  ELSE   
    IF NOT JSON_VALID(_md) THEN
      UPDATE media SET metadata=JSON_OBJECT('_seen_', JSON_OBJECT(_uid, UNIX_TIMESTAMP())) WHERE id=_id;
    END IF; 
    IF _md IS NULL THEN 
      UPDATE media SET metadata=JSON_OBJECT('_seen_', JSON_OBJECT(_uid, UNIX_TIMESTAMP())) WHERE id=_id;
    END IF;
    IF NOT JSON_EXISTS(_md, CONCAT("$._seen_.", _uid)) THEN 
      UPDATE media SET metadata=JSON_MERGE(metadata, JSON_OBJECT('_seen_', JSON_OBJECT(_uid, UNIX_TIMESTAMP()))) WHERE id=_id;
    ELSE 
      UPDATE media SET metadata=JSON_REPLACE(metadata, CONCAT("$._seen_.", _uid), UNIX_TIMESTAMP()) WHERE id=_id;
    END IF;
    IF _show_results THEN 
      SELECT metadata FROM media WHERE id=_id;
    END IF;
  END IF;

END $

-- =======================================================================
-- 
-- =======================================================================
DROP PROCEDURE IF EXISTS `mfs_clear_notifications`$
CREATE PROCEDURE `mfs_clear_notifications`(
  IN _nodes  JSON,
  IN _uid    VARCHAR(16)
)
BEGIN
  DECLARE _i INT(8) DEFAULT 0;
  DECLARE _nid VARCHAR(16);

  WHILE _i < JSON_LENGTH(_nodes) DO 
    SELECT get_json_array(_nodes, _i) INTO _nid;
    SELECT _nid;
    CALL mfs_clear_notification(_nid, _uid, 0);
    SET _i = _i + 1;
  END WHILE;
END $

DELIMITER ;