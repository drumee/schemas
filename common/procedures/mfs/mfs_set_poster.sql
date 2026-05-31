DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_set_poster`$
CREATE PROCEDURE `mfs_set_poster`(
  IN _id VARBINARY(16)
)
BEGIN
  -- Flag a node as having a generated content poster (first-page thumbnail).
  -- Sets metadata.poster=1 without touching publish_time, so a backfill pass
  -- over existing files does NOT make them look "recently modified".
  UPDATE media SET `metadata` =
    JSON_SET( IF(JSON_VALID(metadata), metadata, '{}'), '$.poster', 1)
  WHERE id = _id;
END$

DELIMITER ;
