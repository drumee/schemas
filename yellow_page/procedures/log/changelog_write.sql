DELIMITER $

DROP PROCEDURE IF EXISTS `changelog_write`$
CREATE PROCEDURE `changelog_write`(
  IN _uid VARCHAR(100) CHARACTER SET ascii COLLATE ascii_general_ci,
  IN _hub_id VARCHAR(100) CHARACTER SET ascii COLLATE ascii_general_ci,
  IN _event VARCHAR(100) CHARACTER SET ascii COLLATE ascii_general_ci,
  IN _src JSON,
  IN _dest JSON
)
BEGIN
  INSERT INTO mfs_changelog VALUES(
    null, 
    unix_timestamp(), 
    _uid,
    _hub_id,
    _event,
    _src,
    _dest
  );
  SELECT LAST_INSERT_ID() INTO @max;
  SELECT 
  `id` syncId,
  `hub_id`,
  `timestamp`,
  `event`,
  `src`,
  `dest`
  FROM mfs_changelog WHERE id=@max;
END$

DELIMITER ;
