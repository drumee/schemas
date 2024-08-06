DELIMITER $

-- =======================================================================
-- 
-- =======================================================================
DROP PROCEDURE IF EXISTS `mfs_mark_as_seen`$
CREATE PROCEDURE `mfs_mark_as_seen`(
  IN _id     VARCHAR(16),
  IN _uid    VARCHAR(16),
  IN _show_results BOOLEAN
)
BEGIN
  DECLARE _md JSON;
  DECLARE _seen INT(11) DEFAULT NULL;
  SELECT metadata FROM media WHERE id=_id INTO _md;
  IF _md IS NULL THEN 
    UPDATE media SET metadata=JSON_OBJECT('_seen_', JSON_OBJECT(_uid, UNIX_TIMESTAMP())) WHERE id=_id;
  END IF;
  SELECT metadata FROM media WHERE id=_id INTO _md;
  IF NOT JSON_EXISTS(_md, CONCAT("$._seen_.", _uid)) THEN 
    UPDATE media SET metadata=JSON_MERGE(metadata, JSON_OBJECT('_seen_', JSON_OBJECT(_uid, UNIX_TIMESTAMP()))) WHERE id=_id;
  ELSE 
    UPDATE media SET metadata=JSON_REPLACE(metadata, CONCAT("$._seen_.", _uid), UNIX_TIMESTAMP()) WHERE id=_id;
  END IF;
  IF _show_results THEN 
    SELECT metadata FROM media WHERE id=_id;
  END IF;
END $

DELIMITER ;