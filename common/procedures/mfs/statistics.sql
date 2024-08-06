DELIMITER $

-- ===============================================================
-- 
-- 
-- 
-- ===============================================================
DROP PROCEDURE IF EXISTS `mfs_log_stats`$
CREATE PROCEDURE `mfs_log_stats`(
  IN _nid VARCHAR(16),
  IN _uid VARCHAR(16),
  IN _sid VARCHAR(128)
)
BEGIN
  DECLARE _oid  VARCHAR(16) DEFAULT NULL;
  SELECT owner_id FROM media WHERE id=_nid INTO _oid;
  IF _oid != _uid THEN 
    INSERT INTO media_stats VALUES(null, _nid, _uid, _sid, UNIX_TIMESTAMP());
  END IF;
END $

DELIMITER ;